import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/domain/enums/poll_duration.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_button.dart';
import 'package:yakku/presentation/widgets/app_text_field.dart';
import 'package:yakku/presentation/widgets/section_header.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _questionController = TextEditingController();
  final _optionControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= AppLimits.maxOptions) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= AppLimits.minOptions) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  void _submit() {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    String? error;
    if (question.isEmpty) {
      error = 'Ask a question first.';
    } else if (question.length > AppLimits.maxQuestionLength) {
      error = 'Keep the question under ${AppLimits.maxQuestionLength} characters.';
    } else if (options.length < AppLimits.minOptions) {
      error = 'Add at least ${AppLimits.minOptions} options.';
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    AppScope.of(context).repository.createPoll(
      question: question,
      options: options,
      isAnonymous: true,
      allowMultipleAnswers: false,
      duration: PollDuration.hours24,
    );

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Poll posted anonymously')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Ask Anonymously')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.sm,
                  AppSpacing.screen,
                  AppSpacing.lg + bottomInset,
                ),
                children: [
                  AppTextField(
                    controller: _questionController,
                    hintText: 'Ask your question...',
                    maxLines: 4,
                    maxLength: AppLimits.maxQuestionLength,
                    showCounter: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(
                    title: 'Poll options',
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  ),
                  for (var i = 0; i < _optionControllers.length; i++) ...[
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _optionControllers[i],
                            hintText: 'Option ${i + 1}',
                            maxLength: AppLimits.maxOptionLength,
                          ),
                        ),
                        if (_optionControllers.length > AppLimits.minOptions)
                          IconButton(
                            onPressed: () => _removeOption(i),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (_optionControllers.length < AppLimits.maxOptions)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('+ Add Option'),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.lg,
              ),
              child: AppButton(label: 'Post Poll', onPressed: _submit),
            ),
          ],
        ),
      ),
    );
  }
}
