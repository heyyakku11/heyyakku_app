import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';

class VoteProgressBar extends StatelessWidget {
  const VoteProgressBar({
    super.key,
    required this.progress,
    this.selected = false,
  });

  final double progress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final clamped = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.full),
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: colorScheme.outline.withValues(alpha: 0.35),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: ColoredBox(
                color: selected ? colorScheme.secondary : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VotePercentLabel extends StatelessWidget {
  const VotePercentLabel({
    super.key,
    required this.percent,
    this.selected = false,
  });

  final int percent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(
        '$percent%',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: selected
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
