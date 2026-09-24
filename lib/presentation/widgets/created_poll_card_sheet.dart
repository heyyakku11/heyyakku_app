import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_colors.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/widgets/app_switch.dart';

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

  static const _platforms = [
    _SharePlatform(
      label: 'WhatsApp',
      icon: Icons.chat_rounded,
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF25D366), Color(0xFF25D366)],
      ),
    ),

    _SharePlatform(
      label: 'Instagram',
      icon: Icons.camera_alt_rounded,
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFFFEDA75),
          Color(0xFFFA7E1E),
          Color(0xFFD62976),
          Color(0xFF962FBF),
          Color(0xFF4F5BD5),
        ],
      ),
    ),

    _SharePlatform(
      label: 'Snapchat',
      icon: Icons.snapchat,
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFFFFFC00), Color(0xFFFFFC00)],
      ),
    ),

    _SharePlatform(
      label: 'Copy Link',
      icon: Icons.link,
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xFF6B7280), Color(0xFF6B7280)],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final options = [...poll.options]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final media = MediaQuery.of(context);
    final cardHeight = (media.size.height * 0.5).clamp(420.0, 640.0);

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.xl),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: SafeArea(
          top: true,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                'your yakku is ready!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: cardHeight,
                width: double.infinity,
                child: _PortraitPollCard(
                  question: poll.question,
                  options: options,
                  expiresAt: poll.expiresAt,
                  allowComment: poll.allowComments,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Container(
                decoration: BoxDecoration(color: AppColors.surface),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Share via',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSpacing.xs,
                      mainAxisSpacing: AppSpacing.xs,
                      children: [
                        for (final platform in _platforms)
                          _SharePlatformButton(platform: platform),
                      ],
                    ),
                  ],
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
  const _PortraitPollCard({
    required this.question,
    required this.options,
    required this.expiresAt,
    required this.allowComment,
  });

  final String question;
  final List<PollOptionResponse> options;
  final DateTime expiresAt;
  final bool allowComment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.25,
                fontSize: 26,
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
                      muted: true,
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
            // Row(
            //   children: [
            //     Icon(Icons.lock_clock_outlined),
            //     Text(
            //       expiresAt == null
            //           ? 'No expiry'
            //           : 'Expires in ${expiresAt!.difference(DateTime.now()).inDays} days',
            //     ),
            //   ],
            // ),

            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Allow Comments',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                AppSwitch(value: allowComment, onChanged: (value) => {}),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 10,
              children: [
                Text('Tap to vote', style: TextStyle(fontSize: 18)),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              '🔒 Ask anonymously. Get honest opinions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
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

class _SharePlatform {
  final String label;
  final IconData icon;
  final Gradient gradient;

  const _SharePlatform({
    required this.label,
    required this.icon,
    required this.gradient,
  });
}

class _SharePlatformButton extends StatelessWidget {
  const _SharePlatformButton({required this.platform});

  final _SharePlatform platform;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: platform.gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Icon(platform.icon, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          platform.label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
