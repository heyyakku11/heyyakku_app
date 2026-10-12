import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/auth/open_email_login.dart';
import 'package:yakku/presentation/widgets/remote_poll_list.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).authController;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: auth,
          builder: (context, _) {
            if (!auth.isLoggedIn) {
              return const _LoggedOutActivity();
            }
            return RemotePollList(
              emptyMessage: 'No polls asked yet',
              errorFallback: 'Could not load asked polls',
              ownerActions: true,
              loadPolls: () =>
                  AppScope.of(context).activityPolls.getCreatedPolls(),
            );
          },
        ),
      ),
    );
  }
}

class _LoggedOutActivity extends StatelessWidget {
  const _LoggedOutActivity();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Log in to see your activity',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your asks and updates will show up here once you\'re signed in.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => openEmailLogin(context),
                child: const Text('Log in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
