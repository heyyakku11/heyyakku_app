import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/home/widgets/your_cards_section.dart';
import 'package:yakku/presentation/auth/open_mobile_login.dart';
import 'package:yakku/presentation/screens/inbox/notification_list.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.onAskSomething});

  final VoidCallback? onAskSomething;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  CheckApiRepository? _checkApi;
  bool? _wasLoggedIn;
  List<UserCheckResponse> _myChecks = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);

    if (!identical(_checkApi, scope.checkApi)) {
      _checkApi?.removeListener(_load);
      _checkApi = scope.checkApi..addListener(_load);
    }

    // Reload when the user signs in or out (their made checks change).
    final loggedIn = scope.authController.isLoggedIn;
    if (_wasLoggedIn != loggedIn) {
      _wasLoggedIn = loggedIn;
      _load();
    }
  }

  @override
  void dispose() {
    _checkApi?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final api = _checkApi;
    if (api == null) return;
    try {
      final data = await api.loadHome(loggedIn: _wasLoggedIn ?? false);
      if (!mounted) return;
      setState(() => _myChecks = data.myChecks);
    } catch (_) {
      // Keep the cards already shown; the notifications still load.
    }
  }

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
            return NotificationList(
              source: AppScope.of(context).notifications,
              onAskSomething: widget.onAskSomething,
              header: _myChecks.isEmpty
                  ? null
                  : YourCardsSection(cards: _myChecks),
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
              'Your notifications will show up here once you\'re signed in.',
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
                onPressed: () => openMobileLogin(context),
                child: const Text('Log in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
