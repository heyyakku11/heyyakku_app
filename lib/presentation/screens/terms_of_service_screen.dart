import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service'), centerTitle: false),
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
                        'Welcome to Yakku. By using Yakku, you agree to these Terms of Service.',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      _TermsSection(
                        title: 'Using Yakku',
                        content:
                            'You may use Yakku for personal and lawful purposes. You agree not to misuse the app, disrupt its services, or use it for illegal activities.',
                      ),

                      _TermsSection(
                        title: 'Your Account',
                        content:
                            'You are responsible for keeping your account information secure and for activity performed through your account.',
                      ),

                      _TermsSection(
                        title: 'Your Content',
                        content:
                            'You own the content you create and share on Yakku. By posting content, you give Yakku permission to display and use it as necessary to provide the service.\n\n'
                            'You must not post content that is illegal, harmful, abusive, misleading, or violates another person\'s rights.',
                      ),

                      _TermsSection(
                        title: 'Other Users',
                        content:
                            'Please treat other users respectfully. Yakku is not responsible for interactions or transactions between users.',
                      ),

                      _TermsSection(
                        title: 'Service Availability',
                        content:
                            'We aim to keep Yakku available and reliable, but we cannot guarantee that the service will always be available or error-free.',
                      ),

                      _TermsSection(
                        title: 'Account Termination',
                        content:
                            'We may suspend or terminate accounts that violate these Terms or misuse Yakku.',
                      ),

                      _TermsSection(
                        title: 'Changes to These Terms',
                        content:
                            'We may update these Terms from time to time. Continued use of Yakku after changes means you accept the updated Terms.',
                      ),

                      _TermsSection(
                        title: 'Contact',
                        content:
                            'If you have questions about these Terms, contact us at support@heyyaku.com.',
                        isLast: true,
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

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.title,
    required this.content,
    this.isLast = false,
  });

  final String title;
  final String content;
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

          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
