import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/models/category/category_response.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/created_poll_screen.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';
import 'package:yakku/presentation/widgets/app_switch.dart';
import 'package:yakku/presentation/widgets/app_text_field.dart';

String _capitalizeOption(String value) {
  final text = value.trim();
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
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
  int? _expiryDays;
  bool _allowComments = true;
  final Set<String> _selectedCategoryIds = {};
  List<CategoryResponse> _categories = const [];
  bool _loadingCategories = true;
  String? _categoriesError;
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
    if (_expiryDays != null) return true;
    if (!_allowComments) return true;
    if (_selectedCategoryIds.isNotEmpty) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    if (draft != null) {
      _questionController.text = draft.question;
      _expiryDays = _expiryFromDraft(draft.expiryDays);
      _allowComments = draft.allowComments;
      _selectedCategoryIds.addAll(draft.categoryIds);
    }

    final optionTexts = draft?.options ?? const <String>[];
    final optionCount = _seededOptionCount(optionTexts.length);
    _optionControllers = List.generate(optionCount, (index) {
      final raw = index < optionTexts.length ? optionTexts[index] : '';
      return TextEditingController(text: _capitalizeOption(raw));
    });
    _optionFocusNodes = List.generate(optionCount, (_) => FocusNode());
    _showOptions = _hasQuestion;
    _showExtras = _hasQuestion && _optionsFilled;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCategories();
      if (draft == null) {
        _questionFocus.requestFocus();
      }
    });
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
    });
    try {
      final items = await AppScope.of(context).categories.getCategories();
      if (!mounted) return;
      final active = items
          .where((category) => category.isActive && category.id.isNotEmpty)
          .toList(growable: false);
      setState(() {
        _categories = active;
        _loadingCategories = false;
        _selectedCategoryIds.removeWhere(
          (id) => active.every((category) => category.id != id),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoriesError = DioErrorMapper.map(
          error,
          fallback: 'Could not load categories',
        ).message;
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

  int? _expiryFromDraft(int days) {
    if (days <= 0) return null;
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
        expiryDays: _expiryDays ?? 0,
        allowComments: _allowComments,
        categoryIds: _selectedCategoryIds.toList(growable: false),
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
      _expiryDays = null;
      _allowComments = true;
      _selectedCategoryIds.clear();
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
      expiryDays: _expiryDays,
      allowComments: _allowComments,
      categoryIds: _selectedCategoryIds.toList(growable: false),
    );
  }

  Future<void> _createPoll({
    required String question,
    required List<String> options,
    required int selectedOptionIndex,
    required int? expiryDays,
    required bool allowComments,
    required List<String> categoryIds,
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
        expiresIn: expiryDays == null ? null : Duration(days: expiryDays),
        allowComments: allowComments,
        categoryIds: categoryIds,
      );
      if (!mounted) return;
      final categoryNames = [
        for (final category in _categories)
          if (categoryIds.contains(category.id) &&
              category.name.trim().isNotEmpty)
            category.name.trim(),
      ];
      setState(() => _isCreating = false);
      _resetForm();
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => CreatedPollScreen(
            poll: poll,
            categories: categoryNames,
          ),
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final sheetTheme = Theme.of(context).copyWith(
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.error),
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
                color: Theme.of(context).colorScheme.surface,
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
                                style: textTheme.titleLarge?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
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
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            side: BorderSide(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.outline,
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
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _ExpiryDropdown(
                                            days: _expiryDays,
                                            onChanged: (days) => setState(
                                              () => _expiryDays = days,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: _AllowCommentsToggle(
                                            value: _allowComments,
                                            onChanged: (value) => setState(
                                              () => _allowComments = value,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _CategoryPicker(
                                      categories: _categories,
                                      selectedIds: _selectedCategoryIds,
                                      isLoading: _loadingCategories,
                                      error: _categoriesError,
                                      onToggle: (id) {
                                        setState(() {
                                          if (!_selectedCategoryIds.add(id)) {
                                            _selectedCategoryIds.remove(id);
                                          }
                                        });
                                      },
                                      onRetry: _loadCategories,
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
      shape: CircleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.close,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
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
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          disabledBackgroundColor: Theme.of(
            context,
          ).colorScheme.secondary.withValues(alpha: 0.5),
          disabledForegroundColor: Theme.of(
            context,
          ).colorScheme.onSecondary.withValues(alpha: 0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              )
            : Text(
                'Create',
                style: textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary,
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
      textCapitalization: TextCapitalization.sentences,
      errorText: errorText,
      style: textTheme.bodyLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onChanged: onChanged,
      suffixIcon: onRemove != null
          ? IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Voters can add their own option while voting',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
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

class _ExpiryDropdown extends StatelessWidget {
  const _ExpiryDropdown({required this.days, required this.onChanged});

  final int? days;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w700,
      fontSize: 14,
    );
    final labels = [
      'No expiry',
      for (var day = 1; day <= AppLimits.maxPollExpiryDays; day++)
        day == 1 ? '1 day' : '$day days',
    ];
    return _SettingCard(
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: days ?? 0,
                isDense: true,
                isExpanded: true,
                borderRadius: BorderRadius.circular(AppRadii.md),
                style: labelStyle,
                selectedItemBuilder: (context) => [
                  for (final label in labels)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                    ),
                ],
                items: [
                  for (var i = 0; i < labels.length; i++)
                    DropdownMenuItem(value: i, child: Text(labels[i])),
                ],
                onChanged: (value) =>
                    onChanged(value == null || value == 0 ? null : value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selectedIds,
    required this.isLoading,
    required this.error,
    required this.onToggle,
    required this.onRetry,
  });

  final List<CategoryResponse> categories;
  final Set<String> selectedIds;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onToggle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _SettingCard(
      child: Row(
        children: [
          Icon(
            Icons.sell_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _buildOptions(context, textTheme)),
        ],
      ),
    );
  }

  Widget _buildOptions(BuildContext context, TextTheme textTheme) {
    if (isLoading) {
      return const Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
    }

    if (categories.isEmpty) {
      return Text(
        'No categories available',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Categories',
                style: textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            );
          }
          final category = categories[index - 1];
          final selected = selectedIds.contains(category.id);
          return FilterChip(
            label: Text(category.name),
            selected: selected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            selectedColor: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.18),
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(
              color: selected
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.outline,
            ),
            labelStyle: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => onToggle(category.id),
          );
        },
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
          Icon(
            Icons.chat_bubble_outline,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Allow comments',
              style: textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
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
                    return Theme.of(context).colorScheme.onSecondary;
                  }
                  return Theme.of(context).colorScheme.surface;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.secondary;
                  }
                  return Theme.of(context).colorScheme.outline;
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: child,
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
          'What\'s your opinion?',
          style: textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17,
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
          ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12)
          : Theme.of(context).colorScheme.surface,
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
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'Option $letter',
            style: textTheme.labelMedium?.copyWith(
              color: selected
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
