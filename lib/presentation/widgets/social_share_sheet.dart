import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_colors.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';

Future<void> showSocialShareSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    builder: (sheetContext) {
      return const SocialShareSheet();
    },
  );
}

class SocialShareSheet extends StatelessWidget {
  const SocialShareSheet({super.key});

  static const _platforms = [
    _SharePlatform(
      label: 'Instagram',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFE1306C),
    ),
    _SharePlatform(
      label: 'WhatsApp',
      icon: Icons.chat_rounded,
      color: Color(0xFF25D366),
    ),
    _SharePlatform(
      label: 'Facebook',
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
    ),
    _SharePlatform(
      label: 'Snapchat',
      icon: Icons.flash_on_rounded,
      color: Color(0xFFFFFC00),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
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
              'Share poll',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose a platform',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final platform in _platforms)
                  _SharePlatformButton(platform: platform),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SharePlatform {
  const _SharePlatform({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class _SharePlatformButton extends StatelessWidget {
  const _SharePlatformButton({required this.platform});

  final _SharePlatform platform;

  @override
  Widget build(BuildContext context) {
    final iconColor = platform.color.computeLuminance() > 0.6
        ? AppColors.text
        : Colors.white;

    return Column(
      children: [
        Material(
          color: platform.color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(platform.icon, color: iconColor),
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
