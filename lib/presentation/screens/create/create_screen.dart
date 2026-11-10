import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/repositories/media_upload_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/auth/open_sign_up.dart';
import 'package:yakku/presentation/screens/create/create_poll_claim_screen.dart';
import 'package:yakku/presentation/screens/created_poll_screen.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';

String _capitalizeOption(String value) {
  final text = value.trim();
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Reveal A/B/D once the user starts typing a question.
/// Prefer "first full word" (token + space); also reveal as soon as any
/// non-whitespace is entered so options aren't stuck hidden mid-word.
bool _shouldRevealOptions(String text) {
  return text.trim().isNotEmpty;
}

Future<void> showCreatePollSheet(BuildContext context, {DraftPoll? draft}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: YakkuPalette.transparent,
    builder: (sheetContext) {
      return CreatePollSheet(draft: draft);
    },
  );
}

class CreatePollSheet extends StatefulWidget {
  const CreatePollSheet({super.key, this.draft});

  final DraftPoll? draft;

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet>
    with TickerProviderStateMixin {
  static const _duplicateMessage = 'This option is already used';
  static const _friendsTooltip = "This spot is for your friends' own options.";

  /// Auto-typing question placeholders (loop). Defined only on create screen.
  static const _questionPlaceholderPhrases = <String>[
    'Would you trust me with a secret?',
    'Should I text them first?',
    'Main group mein funny wala hoon ya serious?',
    'Pineapple on pizza is elite.',
  ];

  final _questionController = TextEditingController();
  final _questionFocus = FocusNode();
  late List<TextEditingController> _optionControllers;
  late List<FocusNode> _optionFocusNodes;

  bool _isCreating = false;
  bool _isClosing = false;
  bool _allowPop = false;
  bool _showOptions = false;
  bool _showAddOption = false;
  /// Set when Save is tapped while a mandatory field is empty, so those
  /// fields show a red border until they are filled in.
  bool _showErrors = false;
  bool _allowComments = true;
  bool _stopPlaceholder = false;

  final ImagePicker _imagePicker = ImagePicker();
  File? _photoFile;
  String? _mediaSessionId;
  bool _isUploadingPhoto = false;
  int _mediaSelectionVersion = 0;

  late final AnimationController _screenShakeController;

  bool get _hasQuestion => _questionController.text.trim().isNotEmpty;

  List<({int index, String text})> get _filledOptions {
    final options = <({int index, String text})>[];
    for (var i = 0; i < _optionControllers.length; i++) {
      final text = _optionControllers[i].text.trim();
      if (text.isNotEmpty) {
        options.add((index: i, text: text));
      }
    }
    return options;
  }

  bool get _optionsFilled =>
      _filledOptions.length >= AppLimits.minOptions &&
      _optionControllers
          .take(AppLimits.minOptions)
          .every((controller) => controller.text.trim().isNotEmpty);

  bool get _hasDuplicateOptions {
    final seen = <String>{};
    for (final controller in _optionControllers) {
      final text = controller.text.trim().toLowerCase();
      if (text.isEmpty) continue;
      if (!seen.add(text)) return true;
    }
    return false;
  }

  String? _duplicateErrorFor(int index) {
    final text = _optionControllers[index].text.trim();
    if (text.isEmpty) return null;
    final normalized = text.toLowerCase();
    for (var i = 0; i < _optionControllers.length; i++) {
      if (i == index) continue;
      if (_optionControllers[i].text.trim().toLowerCase() == normalized) {
        return _duplicateMessage;
      }
    }
    return null;
  }

  bool get _formReady =>
      _hasQuestion &&
      _optionsFilled &&
      !_hasDuplicateOptions &&
      !_isCreating &&
      !_isUploadingPhoto;

  /// Save is available once the question and the minimum options are filled.
  bool get _canSave =>
      _formReady && (_photoFile == null || _mediaSessionId != null);

  bool get _hasSavableContent {
    if (_questionController.text.trim().isNotEmpty) return true;
    if (_optionControllers.any(
      (controller) => controller.text.trim().isNotEmpty,
    )) {
      return true;
    }
    if (!_allowComments) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _screenShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    final draft = widget.draft;
    if (draft != null) {
      _questionController.text = draft.question;
      _allowComments = draft.allowComments;
      if (draft.question.trim().isNotEmpty) {
        _stopPlaceholder = true;
      }
    }

    final optionTexts = draft?.options ?? const <String>[];
    final optionCount = _seededOptionCount(optionTexts.length);
    _optionControllers = List.generate(optionCount, (index) {
      final raw = index < optionTexts.length ? optionTexts[index] : '';
      return TextEditingController(text: _capitalizeOption(raw));
    });
    _optionFocusNodes = List.generate(optionCount, (_) => FocusNode());

    _showOptions = _shouldRevealOptions(_questionController.text);
    _showAddOption =
        _optionControllers.isNotEmpty &&
        _optionControllers.first.text.trim().isNotEmpty;
    if (_optionControllers.length > AppLimits.minOptions) {
      _showAddOption = true;
    }

    _questionController.addListener(_onQuestionListen);
    for (final controller in _optionControllers) {
      controller.addListener(_onOptionListen);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      _questionFocus.unfocus();
    });
  }

  @override
  void dispose() {
    _screenShakeController.dispose();
    _questionController.removeListener(_onQuestionListen);
    _questionController.dispose();
    _questionFocus.dispose();
    for (final controller in _optionControllers) {
      controller.removeListener(_onOptionListen);
      controller.dispose();
    }
    for (final node in _optionFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  int _seededOptionCount(int filled) {
    if (filled <= AppLimits.minOptions) return AppLimits.minOptions;
    if (filled >= AppLimits.maxOptions) return AppLimits.maxOptions;
    return filled;
  }

  void _onQuestionListen() {
    final text = _questionController.text;
    final stopPlaceholder = text.isNotEmpty;
    final shouldShow = _shouldRevealOptions(text);
    setState(() {
      if (stopPlaceholder) _stopPlaceholder = true;
      if (shouldShow != _showOptions) {
        _showOptions = shouldShow;
        if (!shouldShow) {
          _showAddOption = false;
        }
      }
    });
    if (!shouldShow && _optionControllers.any((c) => c.text.isNotEmpty)) {
      _resetOptionFields(clearText: true);
    }
  }

  void _onOptionListen() {
    final typedInA =
        _optionControllers.isNotEmpty &&
        _optionControllers.first.text.trim().isNotEmpty;
    final shouldShowAdd =
        typedInA || _optionControllers.length > AppLimits.minOptions;

    if (shouldShowAdd != _showAddOption) {
      setState(() => _showAddOption = shouldShowAdd);
    } else {
      setState(() {});
    }
  }

  Future<void> _onClose() async {
    if (_isClosing || _isCreating) return;
    if (_allowPop) {
      Navigator.of(context).pop();
      return;
    }
    if (!_hasSavableContent) {
      _leaveSheet();
      return;
    }

    _isClosing = true;
    final save = await showAppConfirmDialog(
      context,
      title: 'Save draft?',
      message: 'You have not finished this poll. Save it as a draft?',
      confirmLabel: 'Save draft',
      cancelLabel: "Don't save",
    );
    _isClosing = false;
    if (!mounted || save == null) return;

    if (save) {
      final store = AppScope.of(context).draftPolls;
      if (!store.isReady) {
        await store.open();
      }
      if (!mounted) return;
      await store.save(
        question: _questionController.text.trim(),
        options: _optionControllers
            .map((controller) => controller.text.trim())
            .where((option) => option.isNotEmpty)
            .toList(growable: false),
        expiryDays: 0,
        allowComments: _allowComments,
        categoryIds: const [],
      );
    }
    if (!mounted) return;
    _leaveSheet();
  }

  void _leaveSheet() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  void _showMessage(String message) {
    AppToast.show(message);
  }

  void _addOption() {
    if (_optionControllers.length >= AppLimits.maxOptions) return;
    final controller = TextEditingController();
    final focusNode = FocusNode();
    controller.addListener(_onOptionListen);
    setState(() {
      _optionControllers.add(controller);
      _optionFocusNodes.add(focusNode);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode.requestFocus();
    });
  }

  void _resetOptionFields({bool clearText = true}) {
    for (final node in _optionFocusNodes) {
      if (node.hasFocus) node.unfocus();
    }
    if (clearText) {
      for (final controller in _optionControllers) {
        controller.clear();
      }
    }
    _trimToMinOptions();
  }

  void _trimToMinOptions() {
    if (_optionControllers.length <= AppLimits.minOptions) return;
    final extraControllers = _optionControllers.sublist(AppLimits.minOptions);
    final extraFocus = _optionFocusNodes.sublist(AppLimits.minOptions);
    for (final controller in extraControllers) {
      controller.removeListener(_onOptionListen);
    }
    _optionControllers = _optionControllers.take(AppLimits.minOptions).toList();
    _optionFocusNodes = _optionFocusNodes.take(AppLimits.minOptions).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in extraControllers) {
        controller.dispose();
      }
      for (final node in extraFocus) {
        node.dispose();
      }
    });
  }

  Future<void> _onPhotoChipTap() async {
    final auth = AppScope.of(context).authController;
    if (!auth.isLoggedIn) {
      openSignUp(context);
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: YakkuPalette.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;
    await _pickAndUploadPhoto(source);
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final file = File(picked.path);
      final length = await file.length();
      if (length > MediaUploadRepository.maxImageBytes) {
        _showMessage('Photo must be 10 MB or smaller');
        return;
      }

      final selectionVersion = ++_mediaSelectionVersion;
      setState(() {
        _photoFile = file;
        _mediaSessionId = null;
        _isUploadingPhoto = true;
      });

      final session = await AppScope.of(context).mediaUploads.uploadImageFile(
        file: file,
        selectionVersion: selectionVersion,
        mimeType: picked.mimeType,
      );

      if (!mounted) return;
      if (selectionVersion != _mediaSelectionVersion) return;

      setState(() {
        _mediaSessionId = session.sessionId;
        _isUploadingPhoto = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isUploadingPhoto = false;
        if (_mediaSessionId == null) {
          _photoFile = null;
        }
      });
      _showMessage(
        DioErrorMapper.map(error, fallback: 'Could not upload photo').message,
      );
    }
  }

  void _clearPhoto() {
    _mediaSelectionVersion++;
    setState(() {
      _photoFile = null;
      _mediaSessionId = null;
      _isUploadingPhoto = false;
    });
  }

  void _focusMissingField() {
    if (!_hasQuestion) {
      _questionFocus.requestFocus();
      return;
    }
    for (
      var i = 0;
      i < math.min(AppLimits.minOptions, _optionControllers.length);
      i++
    ) {
      if (_optionControllers[i].text.trim().isEmpty) {
        _optionFocusNodes[i].requestFocus();
        return;
      }
    }
  }

  /// Save: with a mandatory field empty, highlight it; otherwise move on to
  /// the claim screen where the user picks their own answer and creates the
  /// poll.
  Future<void> _onSavePressed() async {
    if (_isCreating || _isUploadingPhoto) return;

    if (!_hasQuestion || !_optionsFilled) {
      HapticFeedback.mediumImpact();
      setState(() => _showErrors = true);
      _screenShakeController.forward(from: 0);
      _focusMissingField();
      return;
    }

    if (_hasDuplicateOptions) {
      HapticFeedback.mediumImpact();
      _showMessage(_duplicateMessage);
      return;
    }

    final question = _questionController.text.trim();
    if (question.length > AppLimits.maxQuestionLength) {
      _showMessage(
        'Question must be at most ${AppLimits.maxQuestionLength} characters.',
      );
      return;
    }

    final options = [
      for (final controller in _optionControllers)
        if (controller.text.trim().isNotEmpty)
          _capitalizeOption(controller.text),
    ];
    if (options.any((option) => option.length > AppLimits.maxOptionLength)) {
      _showMessage(
        'Each option must be at most ${AppLimits.maxOptionLength} characters.',
      );
      return;
    }

    // Creating a poll needs an account; ask before the user picks an answer.
    final auth = AppScope.of(context).authController;
    if (!auth.isLoggedIn) {
      openSignUp(context);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _showErrors = false);
    final poll = await Navigator.of(context).push<PollResponse>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CreatePollClaimScreen(
          question: question,
          options: options,
          mediaUploadSessionId: _mediaSessionId,
        ),
      ),
    );
    if (poll == null || !mounted) return;
    _finishWithPoll(poll);
  }

  /// Closes this sheet and opens the share screen for the new poll.
  void _finishWithPoll(PollResponse poll) {
    setState(() => _allowPop = true);
    final route = MaterialPageRoute<void>(
      builder: (context) => CreatedPollScreen(poll: poll),
    );
    final sheetNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (identical(sheetNavigator, rootNavigator)) {
      unawaited(sheetNavigator.pushReplacement(route));
    } else {
      // Sheet lives in a nested navigator; the poll screen must still cover
      // the whole app, so close the sheet and push on the root navigator.
      sheetNavigator.pop();
      unawaited(rootNavigator.push(route));
    }
  }

  void _moveFocusFromQuestion() {
    if (_showOptions && _optionFocusNodes.isNotEmpty) {
      _optionFocusNodes.first.requestFocus();
    } else {
      _questionFocus.unfocus();
    }
  }

  void _moveFocusFromOption(int index) {
    if (index + 1 < _optionFocusNodes.length) {
      _optionFocusNodes[index + 1].requestFocus();
    } else {
      _optionFocusNodes[index].unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final ready = _canSave;
    // Extra gap above the sheet so the close control clears the status bar.
    const extraTopGap = 24.0;
    final topPadding = media.viewPadding.top + extraTopGap;
    final bottomInset = media.viewInsets.bottom;
    final sheetHeight = media.size.height - topPadding - bottomInset;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isClosing) return;
        _onClose();
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding, bottom: bottomInset),
          child: SizedBox(
            height: sheetHeight,
            child: AnimatedBuilder(
              animation: _screenShakeController,
              builder: (context, child) {
                final t = _screenShakeController.value;
                final dx = math.sin(t * math.pi * 8) * (1 - t) * 8;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: Material(
                color: YakkuPalette.cream,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.xl),
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          12,
                          AppSpacing.screen,
                          AppSpacing.sm,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _CloseButton(onPressed: _onClose),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.sm,
                            AppSpacing.screen,
                            AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _QuestionCard(
                                controller: _questionController,
                                focusNode: _questionFocus,
                                highlightError: _showErrors && !_hasQuestion,
                                stopPlaceholder: _stopPlaceholder,
                                examples: _questionPlaceholderPhrases,
                                onSubmitted: _moveFocusFromQuestion,
                                photoFile: _photoFile,
                                isUploadingPhoto: _isUploadingPhoto,
                                onPhotoTap: _onPhotoChipTap,
                                onClearPhoto: _clearPhoto,
                              ),
                              ClipRect(
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  alignment: Alignment.topCenter,
                                  child: !_showOptions
                                      ? const SizedBox(width: double.infinity)
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            top: AppSpacing.md,
                                          ),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  for (
                                                    var i = 0;
                                                    i <
                                                        _optionControllers
                                                            .length;
                                                    i++
                                                  )
                                                    _StaggerReveal(
                                                      key: ValueKey(
                                                        'option-reveal-$i',
                                                      ),
                                                      index: i,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom:
                                                                  AppSpacing.sm,
                                                            ),
                                                        child: _OptionRow(
                                                          index: i,
                                                          controller:
                                                              _optionControllers[i],
                                                          focusNode:
                                                              _optionFocusNodes[i],
                                                          errorText:
                                                              _duplicateErrorFor(
                                                                i,
                                                              ),
                                                          highlightError:
                                                              _showErrors &&
                                                              i <
                                                                  AppLimits
                                                                      .minOptions &&
                                                              _optionControllers[i]
                                                                  .text
                                                                  .trim()
                                                                  .isEmpty,
                                                          onSubmitted: () =>
                                                              _moveFocusFromOption(
                                                                i,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  _StaggerReveal(
                                                    key: ValueKey(
                                                      'add-reveal-${_optionControllers.length}',
                                                    ),
                                                    index: _optionControllers
                                                        .length,
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom:
                                                            _showAddOption &&
                                                                _optionControllers
                                                                        .length <
                                                                    AppLimits
                                                                        .maxOptions
                                                            ? AppSpacing.sm
                                                            : 0,
                                                      ),
                                                      child: AnimatedSize(
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 200,
                                                            ),
                                                        curve: Curves.easeOut,
                                                        alignment:
                                                            Alignment.topCenter,
                                                        child:
                                                            _showAddOption &&
                                                                _optionControllers
                                                                        .length <
                                                                    AppLimits
                                                                        .maxOptions
                                                            ? _AddOptionButton(
                                                                onPressed:
                                                                    _addOption,
                                                              )
                                                            : const SizedBox(
                                                                width: double
                                                                    .infinity,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                  _StaggerReveal(
                                                    key: const ValueKey(
                                                      'friends-reveal',
                                                    ),
                                                    index:
                                                        _optionControllers
                                                            .length +
                                                        1,
                                                    child: const _FriendsSlot(
                                                      tooltip: _friendsTooltip,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _SaveFooter(
                        ready: ready,
                        isLoading: _isCreating || _isUploadingPhoto,
                        onPressed: _onSavePressed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: const Icon(Icons.close, size: 22, color: YakkuPalette.textPrimary),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.controller,
    required this.focusNode,
    required this.stopPlaceholder,
    required this.examples,
    required this.onSubmitted,
    required this.onPhotoTap,
    required this.onClearPhoto,
    this.highlightError = false,
    this.photoFile,
    this.isUploadingPhoto = false,
  });

  /// Red border: the question is mandatory and still empty.
  final bool highlightError;

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool stopPlaceholder;
  final List<String> examples;
  final VoidCallback onSubmitted;
  final VoidCallback onPhotoTap;
  final VoidCallback onClearPhoto;
  final File? photoFile;
  final bool isUploadingPhoto;

  bool get _nearLimit =>
      controller.text.length >= (AppLimits.maxQuestionLength * 0.85).floor();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showPlaceholder = !stopPlaceholder && controller.text.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlightError
              ? YakkuPalette.redAccent
              : YakkuPalette.primary,
          width: highlightError ? 1.8 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.topLeft,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: false,
                maxLines: null,
                minLines: 3,
                maxLength: AppLimits.maxQuestionLength,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                style: textTheme.titleLarge?.copyWith(
                  color: YakkuPalette.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
                cursorColor: YakkuPalette.primary,
                onSubmitted: (_) => onSubmitted(),
                onEditingComplete: onSubmitted,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) {
                      if (!_nearLimit) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$currentLength/$maxLength',
                          style: textTheme.bodySmall?.copyWith(
                            color: YakkuPalette.textSecondary,
                          ),
                        ),
                      );
                    },
                decoration: const InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: YakkuPalette.transparent,
                  hintText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
              ),
              if (showPlaceholder)
                IgnorePointer(
                  child: _TypingPlaceholder(
                    phrases: examples,
                    style: textTheme.titleLarge?.copyWith(
                      color: YakkuPalette.placeholder,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
            ],
          ),
          if (photoFile != null) ...[
            const SizedBox(height: 12),
            _ImagePreview(
              photoFile: photoFile!,
              isUploading: isUploadingPhoto,
              onClear: onClearPhoto,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Photo chip temporarily disabled.
              // _MediaChip(
              //   icon: Icons.image_outlined,
              //   label: 'Photo',
              //   selected: photoFile != null,
              //   onTap: onPhotoTap,
              // ),
              // Future: Video / Voice media chips.
              // _MediaChip(icon: Icons.videocam_outlined, label: 'Video'),
              // _MediaChip(icon: Icons.mic_none_rounded, label: 'Voice'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypingPlaceholder extends StatefulWidget {
  const _TypingPlaceholder({required this.phrases, required this.style});

  final List<String> phrases;
  final TextStyle? style;

  @override
  State<_TypingPlaceholder> createState() => _TypingPlaceholderState();
}

class _TypingPlaceholderState extends State<_TypingPlaceholder> {
  int _phraseIndex = 0;
  String _visible = '';
  Timer? _timer;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNext() {
    _timer?.cancel();
    final phrase = widget.phrases[_phraseIndex % widget.phrases.length];

    if (!_deleting) {
      if (_visible.length < phrase.length) {
        _timer = Timer(const Duration(milliseconds: 45), () {
          if (!mounted) return;
          setState(() => _visible = phrase.substring(0, _visible.length + 1));
          _scheduleNext();
        });
      } else {
        _timer = Timer(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          _deleting = true;
          _scheduleNext();
        });
      }
      return;
    }

    if (_visible.isNotEmpty) {
      _timer = Timer(const Duration(milliseconds: 25), () {
        if (!mounted) return;
        setState(() => _visible = _visible.substring(0, _visible.length - 1));
        _scheduleNext();
      });
    } else {
      _deleting = false;
      _phraseIndex = (_phraseIndex + 1) % widget.phrases.length;
      _scheduleNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_visible, style: widget.style);
  }
}

class _StaggerReveal extends StatefulWidget {
  const _StaggerReveal({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggerReveal> createState() => _StaggerRevealState();
}

class _StaggerRevealState extends State<_StaggerReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _dy;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _opacity = curved;
    // Slide down from 12px above → settle (top to bottom).
    _dy = Tween<double>(begin: -12, end: 0).animate(curved);

    final delay = Duration(milliseconds: 60 * widget.index);
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _dy.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _OptionRow extends StatefulWidget {
  const _OptionRow({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    this.errorText,
    this.highlightError = false,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final String? errorText;

  /// Red border: this option is mandatory and still empty.
  final bool highlightError;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  String get _letter => String.fromCharCode(65 + widget.index);

  bool get _nearLimit =>
      widget.controller.text.length >=
      (AppLimits.maxOptionLength * 0.85).floor();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final focused = widget.focusNode.hasFocus;
    final highlight = widget.highlightError;
    final borderColor = highlight
        ? YakkuPalette.redAccent
        : focused
        ? YakkuPalette.primary
        : YakkuPalette.stepInactive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
          decoration: BoxDecoration(
            color: YakkuPalette.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: highlight ? 1.8 : (focused ? 1.5 : 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: YakkuPalette.pinkWash,
                ),
                child: Text(
                  _letter,
                  style: textTheme.labelLarge?.copyWith(
                    color: YakkuPalette.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  maxLength: AppLimits.maxOptionLength,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: YakkuPalette.primary,
                  style: textTheme.titleMedium?.copyWith(
                    color: YakkuPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSubmitted: (_) => widget.onSubmitted(),
                  onEditingComplete: widget.onSubmitted,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) {
                        if (!_nearLimit) return const SizedBox.shrink();
                        return Text(
                          '$currentLength/$maxLength',
                          style: textTheme.bodySmall?.copyWith(
                            color: YakkuPalette.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    // Theme defaults to a white fill; keep it transparent.
                    fillColor: YakkuPalette.transparent,
                    hintText: 'Option $_letter',
                    hintStyle: textTheme.titleMedium?.copyWith(
                      color: YakkuPalette.placeholder,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              widget.errorText!,
              style: textTheme.bodySmall?.copyWith(
                color: YakkuPalette.redAccent,
              ),
            ),
          ),
      ],
    );
  }
}

class _AddOptionButton extends StatelessWidget {
  const _AddOptionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YakkuPalette.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DashedRoundedRectPainter(
            color: YakkuPalette.mutedMauve,
            radius: 14,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: YakkuPalette.grey600),
                const SizedBox(width: 6),
                Text(
                  'Add another option',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: YakkuPalette.grey600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendsSlot extends StatelessWidget {
  const _FriendsSlot({required this.tooltip});

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: true,
      child: CustomPaint(
        foregroundPainter: _DashedRoundedRectPainter(
          color: YakkuPalette.primary.withValues(alpha: 0.7),
          radius: 14,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: YakkuPalette.pinkMist,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YakkuPalette.white,
                  border: Border.all(color: YakkuPalette.primary, width: 1.2),
                ),
                child: Text(
                  'D',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: YakkuPalette.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Friends add their own',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: YakkuPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline,
                size: 18,
                color: YakkuPalette.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Save button: raspberry when the mandatory fields are filled, faded
/// otherwise. A faded button still takes taps so the screen can highlight
/// what is missing.
class _SaveFooter extends StatelessWidget {
  const _SaveFooter({
    required this.ready,
    required this.isLoading,
    required this.onPressed,
  });

  final bool ready;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        8,
        AppSpacing.screen,
        16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: ready
                ? YakkuPalette.primary
                : YakkuPalette.primary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Material(
            color: YakkuPalette.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(AppRadii.full),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: YakkuPalette.white,
                        ),
                      )
                    : Text(
                        'Save',
                        style: textTheme.titleMedium?.copyWith(
                          color: YakkuPalette.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.photoFile,
    required this.isUploading,
    required this.onClear,
  });

  final File photoFile;
  final bool isUploading;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.file(
              photoFile,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
        if (isUploading)
          Positioned.fill(
            child: ColoredBox(
              color: YakkuPalette.black.withValues(alpha: 0.35),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: YakkuPalette.white,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: YakkuPalette.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isUploading ? null : onClear,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 16, color: YakkuPalette.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
          Radius.circular(radius),
        ),
      );

    const dashWidth = 5.0;
    const dashSpace = 3.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
