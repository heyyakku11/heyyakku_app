import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_colors.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/domain/enums/poll_duration.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_text_field.dart';

enum _CreatePhase { question, options, review }

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _questionController = TextEditingController();
  late List<TextEditingController> _optionControllers;

  _CreatePhase _phase = _CreatePhase.question;
  bool _myCircleSelected = true;

  bool get _hasQuestion => _questionController.text.trim().isNotEmpty;

  bool get _optionsFilled =>
      _optionControllers.length >= AppLimits.minOptions &&
      _optionControllers.every((controller) => controller.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _optionControllers = List.generate(
      AppLimits.minOptions,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onMediaTap() {
    _showMessage('Coming soon');
  }

  void _addOption() {
    if (_optionControllers.length >= AppLimits.maxOptions) return;
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= AppLimits.minOptions) return;
    final controller = _optionControllers[index];
    setState(() {
      _optionControllers.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _optionControllers.removeAt(oldIndex);
      _optionControllers.insert(newIndex, item);
    });
  }

  void _onNext() {
    FocusScope.of(context).unfocus();
    if (_phase == _CreatePhase.question && _hasQuestion) {
      setState(() => _phase = _CreatePhase.options);
      return;
    }
    if (_phase == _CreatePhase.options && _optionsFilled) {
      setState(() => _phase = _CreatePhase.review);
    }
  }

  void _resetForm() {
    _questionController.clear();
    FocusScope.of(context).unfocus();
    for (final controller in _optionControllers) {
      controller.clear();
    }
    final extras = _optionControllers.length > AppLimits.minOptions
        ? _optionControllers.sublist(AppLimits.minOptions)
        : <TextEditingController>[];
    setState(() {
      _optionControllers = _optionControllers.take(AppLimits.minOptions).toList();
      _phase = _CreatePhase.question;
      _myCircleSelected = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in extras) {
        controller.dispose();
      }
    });
  }

  void _onAskYakku() {
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
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .toList();
    if (options.any((option) => option.length > AppLimits.maxOptionLength)) {
      _showMessage(
        'Each option must be at most ${AppLimits.maxOptionLength} characters.',
      );
      return;
    }

    AppScope.of(context).repository.createPoll(
      question: question,
      options: options,
      isAnonymous: true,
      allowMultipleAnswers: false,
      duration: PollDuration.hours24,
    );
    _resetForm();
    _showMessage('Poll posted anonymously');
  }

  @override
  Widget build(BuildContext context) {
    final showOptions = _phase != _CreatePhase.question;
    final showReview = _phase == _CreatePhase.review;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _questionController,
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
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!showOptions) _MediaRow(onTap: _onMediaTap),
              if (showOptions) ...[
                Row(
                  children: [
                    Text(
                      'Add options',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${_optionControllers.length} / ${AppLimits.maxOptions}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _optionControllers.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    return Padding(
                      key: ValueKey(_optionControllers[index]),
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _OptionTile(
                        index: index,
                        controller: _optionControllers[index],
                        onChanged: (_) => setState(() {}),
                        onRemove: index >= AppLimits.minOptions
                            ? () => _removeOption(index)
                            : null,
                      ),
                    );
                  },
                ),
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
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                        ),
                      ),
                    ),
                  ),
              ],
              if (showReview) ...[
                const SizedBox(height: AppSpacing.sm),
                const _VotersCanAddCard(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Choose audience',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _AudienceCard(
                        title: 'My Circle',
                        subtitle: 'People you know',
                        selected: _myCircleSelected,
                        onTap: () => setState(() => _myCircleSelected = true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _AudienceCard(
                        title: 'Nearby',
                        subtitle: 'Anonymous',
                        selected: !_myCircleSelected,
                        onTap: () => setState(() => _myCircleSelected = false),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_phase == _CreatePhase.question) ...[
                Text(
                  'Ask anything. Get real opinions.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: showReview
                    ? ElevatedButton(
                        onPressed: _optionsFilled && _hasQuestion
                            ? _onAskYakku
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.surface,
                          disabledBackgroundColor: AppColors.border,
                          disabledForegroundColor: AppColors.textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                          ),
                        ),
                        child: const Text('Ask Yakku'),
                      )
                    : ElevatedButton(
                        onPressed: _phase == _CreatePhase.question
                            ? (_hasQuestion ? _onNext : null)
                            : (_optionsFilled ? _onNext : null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          disabledBackgroundColor: AppColors.border,
                          disabledForegroundColor: AppColors.textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                          ),
                        ),
                        child: const Text('Next'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MediaButton(icon: Icons.photo_outlined, label: 'Photo', onTap: onTap),
      ],
    );
  }
}

class _MediaButton extends StatelessWidget {
  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.controller,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: controller,
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
          ),
        ),
        ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.drag_handle_rounded, color: AppColors.textMuted),
          ),
        ),
      ],
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.accent,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
