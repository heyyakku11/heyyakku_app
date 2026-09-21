import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_colors.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_text_field.dart';
import 'package:yakku/presentation/widgets/created_poll_card_sheet.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  static const _revealDuration = Duration(milliseconds: 480);
  static const _revealCurve = Curves.easeOutCubic;

  final _questionController = TextEditingController();
  final _questionFocus = FocusNode();
  late List<TextEditingController> _optionControllers;
  late List<FocusNode> _optionFocusNodes;

  bool _isCreating = false;
  int? _selectedOptionIndex;
  bool _showOptions = false;
  bool _showExtras = false;
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

  bool get _canCreate =>
      _hasQuestion &&
      _optionsFilled &&
      _selectedOptionIndex != null &&
      !_isCreating;

  @override
  void initState() {
    super.initState();
    _optionControllers = List.generate(
      AppLimits.minOptions,
      (_) => TextEditingController(),
    );
    _optionFocusNodes = List.generate(AppLimits.minOptions, (_) => FocusNode());
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
    );
  }

  Future<void> _createPoll({
    required String question,
    required List<String> options,
    required int selectedOptionIndex,
  }) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final poll = await AppScope.of(context).pollApi.createTextPoll(
        question: question,
        options: options,
        selectedOptionIndex: selectedOptionIndex,
      );
      if (!mounted) return;
      setState(() => _isCreating = false);
      _resetForm();
      await showCreatedPollCardSheet(context, poll: poll);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  String _errorMessage(Object error) {
    return DioErrorMapper.map(
      error,
      fallback: 'Could not create poll. Please try again.',
    ).message;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _questionController,
                  focusNode: _questionFocus,
                  hintText: "What's on your mind?",
                  maxLines: 5,
                  maxLength: AppLimits.maxQuestionLength,
                  showCounter: true,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                  onChanged: (_) => _onQuestionChanged(),
                ),
                _SlideReveal(
                  visible: _showOptions,
                  duration: _revealDuration,
                  curve: _revealCurve,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Column(
                      children: [
                        for (var i = 0; i < _optionControllers.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _OptionTile(
                              index: i,
                              controller: _optionControllers[i],
                              focusNode: _optionFocusNodes[i],
                              onChanged: (_) => _onOptionChanged(),
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
                      if (_optionControllers.length < AppLimits.maxOptions)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addOption,
                            icon: const Icon(Icons.add),
                            label: const Text('Add another option'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      const _VotersCanAddCard(),
                      const SizedBox(height: AppSpacing.lg),
                      if (_filledOptions.length >= AppLimits.minOptions)
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
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canCreate ? _onCreate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.surface,
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create poll'),
              ),
            ),
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
    this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      hintText: 'Option ${index + 1}',
      maxLength: AppLimits.maxOptionLength,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      suffixIcon: onRemove != null
          ? IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 20),
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_fix_high_outlined, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Voters can add their own option while voting',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Register your opinion',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Choose the option that matches what you think.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OpinionChoice(
                  letter: String.fromCharCode(65 + i),
                  text: options[i].text,
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
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Option $letter',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
