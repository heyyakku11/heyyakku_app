import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/domain/entities/poll_option.dart';
import 'package:yakku/presentation/widgets/vote_progress_bar.dart';

class PollOptionTile extends StatelessWidget {
  const PollOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.showResults,
    required this.percent,
    required this.onTap,
  });

  final PollOption option;
  final bool selected;
  final bool showResults;
  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = selected
        ? colorScheme.primary
        : colorScheme.outline.withValues(alpha: 0.7);

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.08)
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 20,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      option.text,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (showResults)
                    VotePercentLabel(percent: percent, selected: selected),
                ],
              ),
              if (showResults) ...[
                const SizedBox(height: AppSpacing.sm),
                VoteProgressBar(
                  progress: percent / 100,
                  selected: selected,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
