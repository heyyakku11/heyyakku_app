import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), centerTitle: false),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 600;

            final horizontalPadding = isWideScreen
                ? AppSpacing.xxl
                : AppSpacing.screen;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xl,
                horizontalPadding,
                AppSpacing.xxl,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last updated: September 8, 2026',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Text(
                        'Yakku respects your privacy. This Privacy Policy explains how we collect and use your information when you use the Yakku app.',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      _PrivacySection(
                        title: 'Information We Collect',
                        child: Text(
                          'We may collect information such as your name, email, address, account information, and content you create or submit in the app.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      _PrivacySection(
                        title: 'How We Use Your Information',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'We use your information to:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            const _BulletItem(
                              text: 'Provide and improve Yakku features.',
                            ),
                            const _BulletItem(
                              text: 'Manage your account and authentication.',
                            ),
                            const _BulletItem(
                              text: 'Store and sync your data.',
                            ),
                            const _BulletItem(text: 'Keep the app secure.'),
                          ],
                        ),
                      ),

                      _PrivacySection(
                        title: 'Data Security',
                        child: Text(
                          'We take reasonable measures to protect your information. However, no online service can guarantee complete security.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      _PrivacySection(
                        title: 'Third-Party Services',
                        child: Text(
                          'Yakku may use trusted third-party services for services such as authentication, database hosting, analytics, or app functionality.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      _PrivacySection(
                        title: 'Your Data',
                        child: Text(
                          'You may request access to or deletion of your personal data by contacting us.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      _PrivacySection(
                        title: 'Changes',
                        child: Text(
                          'We may update this Privacy Policy from time to time. Any changes will be reflected in the app or on this page.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      _PrivacySection(
                        title: 'Contact',
                        isLast: true,
                        child: Text(
                          'If you have questions about this Privacy Policy, contact us at support@heyyakku.com.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.title,
    required this.child,
    this.isLast = false,
  });

  final String title;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          child,
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
