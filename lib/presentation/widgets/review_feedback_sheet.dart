import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/presentation/widgets/app_button.dart';
import 'package:yakku/presentation/widgets/app_text_field.dart';

Future<void> showReviewFeedbackSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (sheetContext) => const ReviewFeedbackSheet(),
  );
}

class ReviewFeedbackSheet extends StatefulWidget {
  const ReviewFeedbackSheet({super.key});

  @override
  State<ReviewFeedbackSheet> createState() => _ReviewFeedbackSheetState();
}

class _ReviewFeedbackSheetState extends State<ReviewFeedbackSheet> {
  static const _starCount = 5;

  final _opinionController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _opinionController.dispose();
    super.dispose();
  }

  void _send() {
    if (_rating == 0) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Thanks for your feedback')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Review & Feedback',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'How is Yakku so far?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var star = 1; star <= _starCount; star++)
                    IconButton(
                      onPressed: () => setState(() => _rating = star),
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: star <= _rating
                            ? colors.secondary
                            : colors.onSurfaceVariant,
                        size: 36,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _opinionController,
                hintText: 'Write your opinion (optional)',
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Send',
                onPressed: _rating == 0 ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
