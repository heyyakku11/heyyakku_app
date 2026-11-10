import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/auth/open_sign_up.dart';
import 'package:yakku/presentation/screens/inbox/active_cards_strip.dart';
import 'package:yakku/presentation/screens/inbox/notification_list.dart';
import 'package:yakku/presentation/screens/profile/open_own_card.dart';
import 'package:yakku/presentation/screens/share/open_card_share.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.onAskSomething});

  final VoidCallback? onAskSomething;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  CheckApiRepository? _checkApi;
  bool? _wasLoggedIn;
  List<PollModel> _active = const [];

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
    if (!(_wasLoggedIn ?? false)) {
      if (_active.isNotEmpty) setState(() => _active = const []);
      return;
    }
    try {
      final polls = await AppScope.of(context).activityPolls.getCreatedPolls();
      if (!mounted) return;
      setState(() => _active = _activeCards(polls));
    } catch (_) {
      // Keep the cards already shown; the notifications still load.
    }
  }

  /// Live cards first, then the ones that ended with a result in the last week.
  List<PollModel> _activeCards(List<PollModel> polls) {
    final now = DateTime.now();
    bool live(PollModel p) =>
        p.status.isActive && (p.expiresAt == null || p.expiresAt!.isAfter(now));
    bool recentlyEnded(PollModel p) =>
        !live(p) &&
        p.resultsUnlocked &&
        p.closedAt != null &&
        now.difference(p.closedAt!).inDays < 7;
    return [
      for (final p in polls)
        if (live(p)) p,
      for (final p in polls)
        if (recentlyEnded(p)) p,
    ];
  }

  Future<void> _open(PollModel card) async {
    final changed = await openOwnCardResults(context, card);
    if (changed && mounted) await _load();
  }

  Future<void> _shareAgain(PollModel card) {
    return openCardShare(
      context,
      shareCode: card.shareCode,
      title: card.isCheck ? (card.checkTitle ?? '') : '',
      question: card.question,
      options: [for (final o in card.options) o.text ?? ''],
      minVotes: card.minVotes,
    );
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
              header: _active.isEmpty
                  ? null
                  : ActiveCardsStrip(
                      cards: _active,
                      onOpen: _open,
                      onShareAgain: _shareAgain,
                    ),
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
                onPressed: () => openSignUp(context),
                child: const Text('Log in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
