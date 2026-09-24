import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';
import 'package:yakku/presentation/widgets/app_switch.dart';
import 'package:yakku/presentation/widgets/app_text_field.dart';
import 'package:yakku/presentation/widgets/created_poll_card_sheet.dart';

/// Sheet-local color grading. Promote to AppColors / theme later.
abstract final class _CreateSheetColors {
  static const Color surface = Color(0xFFFFFBF7);
  static const Color background = Color(0xFFF7F4EF);
  static const Color border = Color(0xFFE7EEF0);
  static const Color text = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accent = Color(0xFFE07A5F);
  static const Color error = Color(0xFFB42318);
  static const Color closeIcon = Color(0xFF334155);
  static const Color closeBorder = Color(0xFFE7EEF0);
  static const Color onAccent = Color(0xFFFFFBF7);
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

class _CreatePollSheetState extends State<CreatePollSheet> {
  static const _revealDuration = Duration(milliseconds: 480);
  static const _revealCurve = Curves.easeOutCubic;
  static const _duplicateMessage = 'This option is already used';

  final _questionController = TextEditingController();
  final _questionFocus = FocusNode();
  late List<TextEditingController> _optionControllers;
  late List<FocusNode> _optionFocusNodes;

  bool _isCreating = false;
  bool _isClosing = false;
  bool _allowPop = false;
  int? _selectedOptionIndex;
  bool _showOptions = false;
  bool _showExtras = false;
  int _expiryDays = AppLimits.minPollExpiryDays;
  bool _allowComments = true;
  Timer? _collapseTimer;

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

  bool get _canCreate =>
      _hasQuestion &&
      _optionsFilled &&
      _selectedOptionIndex != null &&
      !_hasDuplicateOptions &&
      !_isCreating;

  bool get _hasSavableContent {
    if (_questionController.text.trim().isNotEmpty) return true;
    if (_optionControllers.any(
      (controller) => controller.text.trim().isNotEmpty,
    )) {
      return true;
    }
    if (_expiryDays != AppLimits.minPollExpiryDays) return true;
    if (!_allowComments) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    if (draft != null) {
      _questionController.text = draft.question;
      _expiryDays = _boundedExpiry(draft.expiryDays);
      _allowComments = draft.allowComments;
    }

    final optionTexts = draft?.options ?? const <String>[];
    final optionCount = _seededOptionCount(optionTexts.length);
    _optionControllers = List.generate(optionCount, (index) {
      final text = index < optionTexts.length ? optionTexts[index] : '';
      return TextEditingController(text: text);
    });
    _optionFocusNodes = List.generate(optionCount, (_) => FocusNode());
    _showOptions = _hasQuestion;
    _showExtras = _hasQuestion && _optionsFilled;

    if (draft == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _questionFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _questionController.dispose();
    _questionFocus.dispose();
    for (final controller in _optionControllers) {
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

  int _boundedExpiry(int days) {
    if (days < AppLimits.minPollExpiryDays) return AppLimits.minPollExpiryDays;
    if (days > AppLimits.maxPollExpiryDays) return AppLimits.maxPollExpiryDays;
    return days;
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
        expiryDays: _expiryDays,
        allowComments: _allowComments,
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

  void _cancelCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = null;
  }

  void _onQuestionChanged() {
    if (_hasQuestion) {
      _cancelCollapseTimer();
      setState(() {
        _showOptions = true;
        _showExtras = _optionsFilled;
      });
      return;
    }
    _onQuestionCleared();
  }

  void _onQuestionCleared() {
    _resetOptionFields();
    if (_showExtras) {
      setState(() => _showExtras = false);
      _cancelCollapseTimer();
      _collapseTimer = Timer(_revealDuration, () {
        if (!mounted || _hasQuestion) return;
        setState(() => _showOptions = false);
      });
      return;
    }
    setState(() => _showOptions = false);
  }

  void _syncExtras() {
    final shouldShow = _hasQuestion && _optionsFilled;
    if (shouldShow) {
      _cancelCollapseTimer();
    }
    setState(() => _showExtras = shouldShow);
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
    setState(() {
      _optionControllers.add(controller);
      _optionFocusNodes.add(focusNode);
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= AppLimits.minOptions) return;
    final controller = _optionControllers[index];
    final focusNode = _optionFocusNodes[index];
    setState(() {
      _optionControllers.removeAt(index);
      _optionFocusNodes.removeAt(index);
      if (_selectedOptionIndex == index) {
        _selectedOptionIndex = null;
      } else if (_selectedOptionIndex != null &&
          _selectedOptionIndex! > index) {
        _selectedOptionIndex = _selectedOptionIndex! - 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
      focusNode.dispose();
    });
  }

  void _selectOpinion(int index) {
    setState(() => _selectedOptionIndex = index);
  }

  void _onOptionChanged() {
    if (_selectedOptionIndex != null) {
      final selected = _optionControllers[_selectedOptionIndex!];
      if (selected.text.trim().isEmpty) {
        _selectedOptionIndex = null;
      }
    }
    _syncExtras();
  }

  void _resetOptionFields() {
    for (final node in _optionFocusNodes) {
      if (node.hasFocus) {
        node.unfocus();
      }
    }
    for (final controller in _optionControllers) {
      controller.clear();
    }
    _selectedOptionIndex = null;
    _trimToMinOptions();
  }

  void _trimToMinOptions() {
    if (_optionControllers.length <= AppLimits.minOptions) return;
    final extraControllers = _optionControllers.sublist(AppLimits.minOptions);
    final extraFocus = _optionFocusNodes.sublist(AppLimits.minOptions);
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
    _cancelCollapseTimer();
    _questionController.clear();
    FocusScope.of(context).unfocus();
    _resetOptionFields();
    setState(() {
      _showOptions = false;
      _showExtras = false;
      _expiryDays = AppLimits.minPollExpiryDays;
      _allowComments = true;
    });
  }

  Future<void> _onCreate() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _showMessage('Ask a question first.');
      return;
    }
    if (question.length > AppLimits.maxQuestionLength) {
      _showMessage(
        'Question must be at most ${AppLimits.maxQuestionLength} characters.',
      );
      return;
    }
    if (!_optionsFilled) {
      _showMessage('Add at least two options.');
      return;
    }
    if (_hasDuplicateOptions) {
      return;
    }
    final selectedIndex = _selectedOptionIndex;
    if (selectedIndex == null) {
      _showMessage('Choose your opinion before creating the poll.');
      return;
    }
    final options = _optionControllers
        .map((controller) => controller.text.trim())
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
      expiryDays: _expiryDays,
      allowComments: _allowComments,
    );
  }

  Future<void> _createPoll({
    required String question,
    required List<String> options,
    required int selectedOptionIndex,
    required int expiryDays,
    required bool allowComments,
  }) async {
    if (_isCreating) return;
    // allowComments is not written onto the local poll payload.
    setState(() => _isCreating = true);

    final poll = PollResponse(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      question: question,
      shareToken: 'local-share',
      optionType: 'text',
      expiresAt: DateTime.now().toUtc().add(Duration(days: expiryDays)),
      allowComments: allowComments,
      totalVoteCount: 1,
      selectedOptionId: 'option-$selectedOptionIndex',
      options: [
        for (var i = 0; i < options.length; i++)
          PollOptionResponse(
            id: 'option-$i',
            text: options[i],
            sortOrder: i,
            voteCount: i == selectedOptionIndex ? 1 : 0,
            percentage: i == selectedOptionIndex ? 100 : 0,
          ),
      ],
    );

    if (!mounted) return;
    setState(() => _isCreating = false);
    _resetForm(); //this reset the create form
    await showCreatedPollCardSheet(context, poll: poll);
    if (mounted) {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sheetTheme = Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        error: _CreateSheetColors.error,
        onError: _CreateSheetColors.surface,
      ),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: _CreateSheetColors.textMuted,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: _CreateSheetColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(
            color: _CreateSheetColors.accent,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: _CreateSheetColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(
            color: _CreateSheetColors.error,
            width: 1.5,
          ),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: _CreateSheetColors.error,
        ),
      ),
    );

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isClosing) return;
        _onClose();
      },
      child: Theme(
        data: sheetTheme,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: SizedBox(
              height: media.size.height - media.viewInsets.bottom,
              child: Material(
                color: _CreateSheetColors.surface,
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
                          50,
                          AppSpacing.screen,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            _CloseButton(onPressed: () => _onClose()),
                            const Spacer(),
                            _CreateButton(
                              enabled: _canCreate,
                              isLoading: _isCreating,
                              onPressed: _onCreate,
                            ),
                          ],
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                controller: _questionController,
                                focusNode: _questionFocus,
                                hintText: "What's on your mind?",
                                maxLines: 4,
                                maxLength: AppLimits.maxQuestionLength,
                                showCounter: true,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                style: textTheme.titleMedium?.copyWith(
                                  color: _CreateSheetColors.text,
                                  height: 1.35,
                                ),
                                onChanged: (_) => _onQuestionChanged(),
                              ),
                              _SlideReveal(
                                visible: _showOptions,
                                duration: _revealDuration,
                                curve: _revealCurve,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.lg,
                                  ),
                                  child: Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < _optionControllers.length;
                                        i++
                                      )
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.md,
                                          ),
                                          child: _OptionTile(
                                            index: i,
                                            controller: _optionControllers[i],
                                            focusNode: _optionFocusNodes[i],
                                            errorText: _duplicateErrorFor(i),
                                            onChanged: (_) =>
                                                _onOptionChanged(),
                                            onRemove: i >= AppLimits.minOptions
                                                ? () => _removeOption(i)
                                                : null,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              _SlideReveal(
                                visible: _showExtras,
                                duration: _revealDuration,
                                curve: _revealCurve,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_optionControllers.length <
                                        AppLimits.maxOptions)
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: _addOption,
                                          icon: const Icon(Icons.add),
                                          label: Text(
                                            'Add another option',
                                            style: textTheme.titleMedium
                                                ?.copyWith(
                                                  color:
                                                      _CreateSheetColors.text,
                                                ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                _CreateSheetColors.text,
                                            side: const BorderSide(
                                              color: _CreateSheetColors.border,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadii.lg,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: AppSpacing.md),
                                    const _VotersCanAddCard(),
                                    const SizedBox(height: AppSpacing.md),
                                    _ExpiryStepper(
                                      days: _expiryDays,
                                      onChanged: (days) =>
                                          setState(() => _expiryDays = days),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _AllowCommentsToggle(
                                      value: _allowComments,
                                      onChanged: (value) => setState(
                                        () => _allowComments = value,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    if (_filledOptions.length >=
                                        AppLimits.minOptions)
                                      _OpinionGrid(
                                        options: _filledOptions,
                                        selectedIndex: _selectedOptionIndex,
                                        onSelected: _selectOpinion,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(
        side: BorderSide(color: _CreateSheetColors.closeBorder),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.close,
            size: 20,
            color: _CreateSheetColors.closeIcon,
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 40,
      width: 100,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _CreateSheetColors.accent,
          foregroundColor: _CreateSheetColors.onAccent,
          disabledBackgroundColor: _CreateSheetColors.accent.withValues(
            alpha: 0.5,
          ),
          disabledForegroundColor: _CreateSheetColors.onAccent.withValues(
            alpha: 0.5,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _CreateSheetColors.onAccent,
                ),
              )
            : Text(
                'Create',
                style: textTheme.titleMedium?.copyWith(
                  color: _CreateSheetColors.onAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

class _SlideReveal extends StatelessWidget {
  const _SlideReveal({
    required this.visible,
    required this.child,
    required this.duration,
    required this.curve,
  });

  final bool visible;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSize(
        duration: duration,
        curve: curve,
        alignment: Alignment.topCenter,
        child: visible
            ? AnimatedOpacity(
                duration: duration,
                curve: curve,
                opacity: 1,
                child: child,
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.errorText,
    this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      hintText: 'Option ${index + 1}',
      maxLength: AppLimits.maxOptionLength,
      textInputAction: TextInputAction.next,
      errorText: errorText,
      style: textTheme.bodyLarge?.copyWith(color: _CreateSheetColors.text),
      onChanged: onChanged,
      suffixIcon: onRemove != null
          ? IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.close,
                size: 20,
                color: _CreateSheetColors.textMuted,
              ),
            )
          : null,
    );
  }
}

class _VotersCanAddCard extends StatelessWidget {
  const _VotersCanAddCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _CreateSheetColors.background,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: _CreateSheetColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: _CreateSheetColors.closeIcon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Voters can add their own option while voting',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _CreateSheetColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryStepper extends StatelessWidget {
  const _ExpiryStepper({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int> onChanged;

  String get _label => days == 1 ? '1 day' : '$days days';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final atMin = days <= AppLimits.minPollExpiryDays;
    final atMax = days >= AppLimits.maxPollExpiryDays;
    return _SettingCard(
      child: Row(
        children: [
          const Icon(Icons.schedule, color: _CreateSheetColors.closeIcon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Poll expires in',
              style: textTheme.titleMedium?.copyWith(
                color: _CreateSheetColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.remove,
            enabled: !atMin,
            onPressed: () => onChanged(days - 1),
          ),
          SizedBox(
            width: 64,
            child: Text(
              _label,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: _CreateSheetColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            enabled: !atMax,
            onPressed: () => onChanged(days + 1),
          ),
        ],
      ),
    );
  }
}

class _AllowCommentsToggle extends StatelessWidget {
  const _AllowCommentsToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _SettingCard(
      child: Row(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: _CreateSheetColors.closeIcon,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Allow comments on this poll',
              style: textTheme.titleMedium?.copyWith(
                color: _CreateSheetColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _CreateSheetColors.onAccent;
                  }
                  return _CreateSheetColors.surface;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _CreateSheetColors.accent;
                  }
                  return _CreateSheetColors.border;
                }),
                trackOutlineColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
              ),
            ),
            child: AppSwitch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _CreateSheetColors.background,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: _CreateSheetColors.border),
      ),
      child: child,
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: CircleBorder(
        side: BorderSide(
          color: enabled
              ? _CreateSheetColors.border
              : _CreateSheetColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? _CreateSheetColors.closeIcon
                : _CreateSheetColors.textMuted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _OpinionGrid extends StatelessWidget {
  const _OpinionGrid({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<({int index, String text})> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'What do YOU think?',
          style: textTheme.titleMedium?.copyWith(
            color: _CreateSheetColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OpinionChoice(
                  letter: String.fromCharCode(65 + i),
                  selected: selectedIndex == options[i].index,
                  onTap: () => onSelected(options[i].index),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _OpinionChoice extends StatelessWidget {
  const _OpinionChoice({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected
          ? _CreateSheetColors.accent.withValues(alpha: 0.12)
          : _CreateSheetColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected
                  ? _CreateSheetColors.accent
                  : _CreateSheetColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'Option $letter',
            style: textTheme.labelMedium?.copyWith(
              color: selected
                  ? _CreateSheetColors.accent
                  : _CreateSheetColors.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
