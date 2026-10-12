import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';
import 'package:yakku/presentation/app_scope.dart';
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
    backgroundColor: Colors.transparent,
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
  static const _examplePhrases = <String>[
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
  int? _selectedOptionIndex;
  bool _showOptions = false;
  bool _showAddOption = false;
  bool _showPickHint = false;
  bool _allowComments = true;
  bool _stopPlaceholder = false;
  Timer? _pickHintTimer;

  late final AnimationController _buttonShakeController;
  late final AnimationController _radioPulseController;
  late final AnimationController _screenShakeController;
  late final AnimationController _glowController;

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
      _hasQuestion && _optionsFilled && !_hasDuplicateOptions && !_isCreating;

  bool get _canCreate => _formReady && _selectedOptionIndex != null;

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
    _buttonShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _radioPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _screenShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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
    _showAddOption = _optionControllers.isNotEmpty &&
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
    _pickHintTimer?.cancel();
    _buttonShakeController.dispose();
    _radioPulseController.dispose();
    _screenShakeController.dispose();
    _glowController.dispose();
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
          _showPickHint = false;
        }
      }
    });
    if (!shouldShow && _optionControllers.any((c) => c.text.isNotEmpty)) {
      _resetOptionFields(clearText: true);
    }
  }

  void _onOptionListen() {
    if (_selectedOptionIndex != null) {
      final selected = _optionControllers[_selectedOptionIndex!];
      if (selected.text.trim().isEmpty) {
        _selectedOptionIndex = null;
        _glowController.stop();
        _glowController.value = 0;
      }
    }

    final typedInA = _optionControllers.isNotEmpty &&
        _optionControllers.first.text.trim().isNotEmpty;
    final shouldShowAdd = typedInA ||
        _optionControllers.length > AppLimits.minOptions;

    if (shouldShowAdd != _showAddOption) {
      setState(() => _showAddOption = shouldShowAdd);
    } else {
      setState(() {});
    }

    if (_canCreate) {
      if (!_glowController.isAnimating) {
        _glowController.repeat();
      }
    } else {
      _glowController.stop();
      _glowController.value = 0;
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

  void _selectOpinion(int index) {
    if (_optionControllers[index].text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedOptionIndex = index;
      _showPickHint = false;
    });
    _pickHintTimer?.cancel();
    if (!_glowController.isAnimating) {
      _glowController.repeat();
    }
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
    _selectedOptionIndex = null;
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

  void _resetForm() {
    _pickHintTimer?.cancel();
    _questionController.clear();
    FocusScope.of(context).unfocus();
    _resetOptionFields();
    _glowController.stop();
    _glowController.value = 0;
    setState(() {
      _showOptions = false;
      _showAddOption = false;
      _showPickHint = false;
      _allowComments = true;
      _stopPlaceholder = false;
    });
  }

  void _focusMissingField() {
    if (!_hasQuestion) {
      _questionFocus.requestFocus();
      return;
    }
    for (var i = 0; i < math.min(AppLimits.minOptions, _optionControllers.length); i++) {
      if (_optionControllers[i].text.trim().isEmpty) {
        _optionFocusNodes[i].requestFocus();
        return;
      }
    }
  }

  Future<void> _onAskPressed() async {
    if (_isCreating) return;

    if (!_hasQuestion || !_optionsFilled) {
      HapticFeedback.mediumImpact();
      _screenShakeController.forward(from: 0);
      _focusMissingField();
      return;
    }

    if (_hasDuplicateOptions) {
      _showMessage(_duplicateMessage);
      return;
    }

    if (_selectedOptionIndex == null) {
      HapticFeedback.mediumImpact();
      _buttonShakeController.forward(from: 0);
      _radioPulseController.forward(from: 0);
      setState(() => _showPickHint = true);
      _pickHintTimer?.cancel();
      _pickHintTimer = Timer(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        setState(() => _showPickHint = false);
      });
      return;
    }

    await _onCreate();
  }

  Future<void> _onCreate() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _focusMissingField();
      return;
    }
    if (question.length > AppLimits.maxQuestionLength) {
      _showMessage(
        'Question must be at most ${AppLimits.maxQuestionLength} characters.',
      );
      return;
    }
    if (!_optionsFilled) {
      _focusMissingField();
      return;
    }
    if (_hasDuplicateOptions) return;
    final selectedIndex = _selectedOptionIndex;
    if (selectedIndex == null) return;

    final options = _optionControllers
        .map((controller) => _capitalizeOption(controller.text))
        .toList();
    if (options.any((option) => option.length > AppLimits.maxOptionLength)) {
      _showMessage(
        'Each option must be at most ${AppLimits.maxOptionLength} characters.',
      );
      return;
    }

    await _createPoll(
      question: question,
      options: options,
      selectedOptionIndex: selectedIndex,
      allowComments: _allowComments,
    );
  }

  Future<void> _createPoll({
    required String question,
    required List<String> options,
    required int selectedOptionIndex,
    required bool allowComments,
  }) async {
    if (_isCreating) return;

    final filled = <String>[];
    int? apiSelectedIndex;
    for (var i = 0; i < options.length; i++) {
      final text = options[i].trim();
      if (text.isEmpty) continue;
      if (i == selectedOptionIndex) {
        apiSelectedIndex = filled.length;
      }
      filled.add(text);
    }
    if (apiSelectedIndex == null) {
      _showMessage('Choose your opinion before creating the poll.');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final poll = await AppScope.of(context).pollApi.createTextPoll(
        question: question,
        options: filled,
        selectedOptionIndex: apiSelectedIndex,
        allowComments: allowComments,
      );
      if (!mounted) return;
      setState(() => _isCreating = false);
      _resetForm();
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => CreatedPollScreen(poll: poll),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _showMessage(
        DioErrorMapper.map(error, fallback: 'Could not create poll').message,
      );
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
    final ready = _canCreate;

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
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: media.size.height - media.viewInsets.bottom,
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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          20,
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
                                stopPlaceholder: _stopPlaceholder,
                                examples: _examplePhrases,
                                onSubmitted: _moveFocusFromQuestion,
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
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              for (var i = 0;
                                                  i <
                                                      _optionControllers
                                                          .length;
                                                  i++)
                                                _StaggerReveal(
                                                  key: ValueKey(
                                                    'option-reveal-$i',
                                                  ),
                                                  index: i,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      bottom: AppSpacing.sm,
                                                    ),
                                                    child: _OptionRow(
                                                      index: i,
                                                      controller:
                                                          _optionControllers[
                                                              i],
                                                      focusNode:
                                                          _optionFocusNodes[i],
                                                      selected:
                                                          _selectedOptionIndex ==
                                                              i,
                                                      showRadio:
                                                          _optionControllers[i]
                                                              .text
                                                              .trim()
                                                              .isNotEmpty,
                                                      errorText:
                                                          _duplicateErrorFor(
                                                        i,
                                                      ),
                                                      pulseListenable:
                                                          _radioPulseController,
                                                      onSelect: () =>
                                                          _selectOpinion(i),
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
                                                index:
                                                    _optionControllers.length,
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: _showAddOption &&
                                                            _optionControllers
                                                                    .length <
                                                                AppLimits
                                                                    .maxOptions
                                                        ? AppSpacing.sm
                                                        : 0,
                                                  ),
                                                  child: AnimatedSize(
                                                    duration: const Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    curve: Curves.easeOut,
                                                    alignment:
                                                        Alignment.topCenter,
                                                    child: _showAddOption &&
                                                            _optionControllers
                                                                    .length <
                                                                AppLimits
                                                                    .maxOptions
                                                        ? _AddOptionButton(
                                                            onPressed:
                                                                _addOption,
                                                          )
                                                        : const SizedBox(
                                                            width:
                                                                double.infinity,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                              _StaggerReveal(
                                                key: const ValueKey(
                                                  'friends-reveal',
                                                ),
                                                index:
                                                    _optionControllers.length +
                                                        1,
                                                child: const _FriendsSlot(
                                                  tooltip: _friendsTooltip,
                                                ),
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
                      _AskFooter(
                        ready: ready,
                        isLoading: _isCreating,
                        showPickHint: _showPickHint,
                        showPrivacy: _optionsFilled,
                        picked: _selectedOptionIndex != null,
                        shakeListenable: _buttonShakeController,
                        glowListenable: _glowController,
                        onPressed: _onAskPressed,
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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool stopPlaceholder;
  final List<String> examples;
  final VoidCallback onSubmitted;

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: YakkuPalette.primary, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (showPlaceholder)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _TypingPlaceholder(
                        phrases: examples,
                        style: textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFB0A4A7),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
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
                buildCounter: (
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
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MediaChip(icon: Icons.image_outlined, label: 'Photo'),
              _MediaChip(icon: Icons.videocam_outlined, label: 'Video'),
              _MediaChip(icon: Icons.mic_none_rounded, label: 'Voice'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaChip extends StatelessWidget {
  const _MediaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => HapticFeedback.selectionClick(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: YakkuPalette.textPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: YakkuPalette.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
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
  const _StaggerReveal({
    super.key,
    required this.index,
    required this.child,
  });

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
    required this.selected,
    required this.showRadio,
    required this.onSelect,
    required this.onSubmitted,
    required this.pulseListenable,
    this.errorText,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool selected;
  final bool showRadio;
  final VoidCallback onSelect;
  final VoidCallback onSubmitted;
  final Animation<double> pulseListenable;
  final String? errorText;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow>
    with TickerProviderStateMixin {
  late final AnimationController _popController;
  late final AnimationController _radioInController;
  late final AnimationController _appearPulseController;
  bool _wasSelected = false;
  bool _wasShowingRadio = false;

  String get _letter => String.fromCharCode(65 + widget.index);

  bool get _nearLimit =>
      widget.controller.text.length >=
      (AppLimits.maxOptionLength * 0.85).floor();

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _radioInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: widget.showRadio ? 1 : 0,
    );
    _appearPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _wasSelected = widget.selected;
    _wasShowingRadio = widget.showRadio;
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _OptionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !_wasSelected) {
      _popController.forward(from: 0);
    }
    _wasSelected = widget.selected;

    if (widget.showRadio && !_wasShowingRadio) {
      _radioInController.forward(from: 0).whenComplete(() {
        if (!mounted || widget.selected) return;
        _appearPulseController.forward(from: 0);
      });
    } else if (!widget.showRadio && _wasShowingRadio) {
      _radioInController.value = 0;
    }
    _wasShowingRadio = widget.showRadio;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _popController.dispose();
    _radioInController.dispose();
    _appearPulseController.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  double _popScale() {
    final t = Curves.easeOut.transform(_popController.value);
    if (t < 0.45) {
      return 0.94 + (1.04 - 0.94) * (t / 0.45);
    }
    return 1.04 + (1.0 - 1.04) * ((t - 0.45) / 0.55);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final focused = widget.focusNode.hasFocus;
    final selected = widget.selected;
    final borderColor = selected
        ? Colors.transparent
        : focused
            ? YakkuPalette.primary
            : const Color(0xFFE5DCDF);
    final fill = selected ? const Color(0xFF1C1A1B) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _popController,
          builder: (context, child) {
            return Transform.scale(
              scale: selected ? _popScale() : 1,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: focused && !selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? YakkuPalette.primary
                        : const Color(0xFFF7D5E2),
                  ),
                  child: Text(
                    _letter,
                    style: textTheme.labelLarge?.copyWith(
                      color: selected ? Colors.white : YakkuPalette.primary,
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
                      color: selected ? Colors.white : YakkuPalette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSubmitted: (_) => widget.onSubmitted(),
                    onEditingComplete: widget.onSubmitted,
                    buildCounter: (
                      context, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) {
                      if (!_nearLimit) return const SizedBox.shrink();
                      return Text(
                        '$currentLength/$maxLength',
                        style: textTheme.bodySmall?.copyWith(
                          color: selected
                              ? Colors.white70
                              : YakkuPalette.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      // Theme defaults to white fill — keep transparent so the
                      // selected dark row (and white text) stay readable.
                      fillColor: Colors.transparent,
                      hintText: 'Option $_letter',
                      hintStyle: textTheme.titleMedium?.copyWith(
                        color: selected
                            ? Colors.white54
                            : const Color(0xFFB0A4A7),
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
                if (widget.showRadio)
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.6, end: 1).animate(
                      CurvedAnimation(
                        parent: _radioInController,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _radioInController,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            widget.pulseListenable,
                            _appearPulseController,
                          ]),
                          builder: (context, child) {
                            final validatePulse = widget.pulseListenable.value;
                            final appearPulse = _appearPulseController.value;
                            final pulse = math.max(validatePulse, appearPulse);
                            final pulseScale =
                                1 + math.sin(pulse * math.pi * 2) * 0.08;
                            final glowing = !selected && pulse > 0 && pulse < 1;
                            return Transform.scale(
                              scale: selected ? 1 : pulseScale,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: glowing
                                      ? [
                                          BoxShadow(
                                            color: YakkuPalette.primary
                                                .withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: GestureDetector(
                            onTap: widget.onSelect,
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? YakkuPalette.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: selected
                                      ? YakkuPalette.primary
                                      : YakkuPalette.primary.withValues(
                                          alpha: 0.55,
                                        ),
                                  width: 1.6,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              widget.errorText!,
              style: textTheme.bodySmall?.copyWith(color: Colors.redAccent),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DashedRoundedRectPainter(
            color: const Color(0xFFD0C6C8),
            radius: 14,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Add another option',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
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
            color: const Color(0xFFFCE8EF),
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
                  color: Colors.white,
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

class _AskFooter extends StatelessWidget {
  const _AskFooter({
    required this.ready,
    required this.isLoading,
    required this.showPickHint,
    required this.showPrivacy,
    required this.picked,
    required this.shakeListenable,
    required this.glowListenable,
    required this.onPressed,
  });

  final bool ready;
  final bool isLoading;
  final bool showPickHint;
  final bool showPrivacy;
  final bool picked;
  final Animation<double> shakeListenable;
  final Animation<double> glowListenable;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            opacity: showPickHint ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Pick your answer first',
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE11D48),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([shakeListenable, glowListenable]),
            builder: (context, child) {
              final shakeT = shakeListenable.value;
              final dx = math.sin(shakeT * math.pi * 8) * (1 - shakeT) * 10;
              final glow = ready
                  ? (0.18 + 0.18 * (0.5 + 0.5 * math.sin(glowListenable.value * math.pi * 2)))
                  : 0.0;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    boxShadow: ready
                        ? [
                            BoxShadow(
                              color: YakkuPalette.primary.withValues(
                                alpha: glow,
                              ),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: child,
                ),
              );
            },
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: ready ? YakkuPalette.primary : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(color: YakkuPalette.primary, width: 1.4),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoading ? null : onPressed,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: ready
                                    ? Colors.white
                                    : YakkuPalette.primary,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.ios_share_rounded,
                                  size: 18,
                                  color: ready
                                      ? Colors.white
                                      : YakkuPalette.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ask my friends',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: ready
                                        ? Colors.white
                                        : YakkuPalette.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: showPrivacy && !showPickHint ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: YakkuPalette.textSecondary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    picked
                        ? 'Only you know your pick'
                        : 'Only you see your pick',
                    style: textTheme.bodySmall?.copyWith(
                      color: YakkuPalette.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
