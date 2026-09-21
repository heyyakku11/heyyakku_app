import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_colors.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/widgets/social_share_sheet.dart';

Future<void> showCreatedPollCardSheet(
  BuildContext context, {
  required PollResponse poll,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return CreatedPollCardSheet(poll: poll);
    },
  );
}

class CreatedPollCardSheet extends StatelessWidget {
  const CreatedPollCardSheet({super.key, required this.poll});

  final PollResponse poll;

  @override
  Widget build(BuildContext context) {
    final options = [...poll.options]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final media = MediaQuery.of(context);
    final cardHeight = (media.size.height * 0.62).clamp(420.0, 640.0);

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.xl),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your poll is live',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: cardHeight,
                width: double.infinity,
                child: _PortraitPollCard(
                  question: poll.question,
                  options: options,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => showSocialShareSheet(context),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortraitPollCard extends StatelessWidget {
  const _PortraitPollCard({required this.question, required this.options});

  final String question;
  final List<PollOptionResponse> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yakku',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              question,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    _CardOptionRow(
                      letter: String.fromCharCode(65 + i),
                      text: options[i].text ?? '',
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const _CardOptionRow(
                    letter: '+',
                    text: AppLimits.somethingElseLabel,
                    muted: true,
                  ),
                ],
              ),
            ),
            Text(
              'Ask anonymously. Get honest opinions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardOptionRow extends StatelessWidget {
  const _CardOptionRow({
    required this.letter,
    required this.text,
    this.muted = false,
  });

  final String letter;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: muted ? AppColors.background : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: muted
                ? AppColors.border
                : AppColors.accent.withValues(alpha: 0.18),
            child: Text(
              letter,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: muted ? AppColors.textMuted : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: muted ? AppColors.textMuted : AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
