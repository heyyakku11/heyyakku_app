import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/answer_poll_screen.dart';

enum _SharedPollIssue {
  notFound,
  unavailable,
  closed,
  expired,
  failed,
  alreadyVoted,
  ownCard,
  cannotVote,
}

/// Destination of `https://<web host>/vote/{shareCode}` links. Loads the poll
/// through the share-code API (the same card the website loads) and hands it to
/// [AnswerPollScreen]. Voting needs a full login: signed-in users are checked
/// against the API's voting state (already voted / own card / blocked), and
/// everyone else sees the card with a "Log in to vote" prompt.
class SharedPollScreen extends StatefulWidget {
  const SharedPollScreen({super.key, required this.shareCode});

  final String shareCode;

  @override
  State<SharedPollScreen> createState() => _SharedPollScreenState();
}

class _SharedPollScreenState extends State<SharedPollScreen> {
  PollResponse? _poll;
  _SharedPollIssue? _issue;
  bool _started = false;
  AuthController? _auth;

  /// Login state the card was loaded with; its voting state is only valid for
  /// that user, so a login mid-screen reloads it.
  bool? _loadedLoggedIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AppScope.of(context).authController;
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_onAuthChanged);
      _auth = auth..addListener(_onAuthChanged);
    }
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted || _loadedLoggedIn == _auth?.isLoggedIn) return;
    _load(silent: true);
  }

  /// [silent] refreshes without replacing the card, so what the user has typed
  /// on it is kept.
  Future<void> _load({bool silent = false}) async {
    if (!PollDeepLink.isValidShareCode(widget.shareCode)) {
      setState(() => _issue = _SharedPollIssue.notFound);
      return;
    }
    if (!silent) {
      setState(() {
        _poll = null;
        _issue = null;
      });
    }
    final scope = AppScope.of(context);
    final loggedIn = scope.authController.isLoggedIn;
    try {
      final poll = await scope.pollApi.getPollByShareCode(widget.shareCode);
      if (!mounted) return;
      _loadedLoggedIn = loggedIn;
      final issue = _issueFor(poll, loggedIn: loggedIn);
      setState(() {
        _issue = issue;
        _poll = issue == null ? poll : null;
      });
    } on DioException catch (error) {
      if (!mounted || silent) return;
      final status = error.response?.statusCode;
      setState(() {
        _issue = switch (status) {
          400 || 404 => _SharedPollIssue.notFound,
          401 || 403 => _SharedPollIssue.unavailable,
          _ => _SharedPollIssue.failed,
        };
      });
    } catch (_) {
      if (!mounted || silent) return;
      setState(() => _issue = _SharedPollIssue.failed);
    }
  }

  /// UI-level hint only; the backend remains the authority on vote validity.
  _SharedPollIssue? _issueFor(PollResponse poll, {required bool loggedIn}) {
    if (poll.id.isEmpty || poll.options.isEmpty) {
      return _SharedPollIssue.notFound;
    }
    final status = poll.status.toLowerCase();
    if (status == 'closed') return _SharedPollIssue.closed;
    if (status == 'expired') return _SharedPollIssue.expired;
    if (status != 'active') return _SharedPollIssue.unavailable;
    final expiresAt = poll.expiresAt;
    if (expiresAt != null && !expiresAt.isAfter(DateTime.now())) {
      return _SharedPollIssue.expired;
    }
    // Logged-out users still see the card; they are asked to log in on submit.
    final voting = poll.voting;
    if (!loggedIn || voting == null) return null;
    if (poll.isOwner) return _SharedPollIssue.ownCard;
    if (voting.hasVoted) return _SharedPollIssue.alreadyVoted;
    if (!voting.canVote) {
      debugPrint('Shared card not votable: ${voting.blockedReason}');
      return _SharedPollIssue.cannotVote;
    }
    return null;
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = _poll;
    if (poll != null) return AnswerPollScreen(poll: poll);

    final issue = _issue;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: _leave,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: issue == null
              ? const CircularProgressIndicator()
              : _IssueView(issue: issue, onRetry: _load, onLeave: _leave),
        ),
      ),
    );
  }
}

class _IssueView extends StatelessWidget {
  const _IssueView({
    required this.issue,
    required this.onRetry,
    required this.onLeave,
  });

  final _SharedPollIssue issue;
  final VoidCallback onRetry;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, body) = switch (issue) {
      _SharedPollIssue.notFound => (
        'Poll not found',
        'This poll may have been removed or the link might be broken.',
      ),
      _SharedPollIssue.unavailable => (
        'Poll unavailable',
        "This poll isn't available for voting.",
      ),
      _SharedPollIssue.closed => (
        'Poll closed',
        'This poll is closed and no longer accepts votes.',
      ),
      _SharedPollIssue.expired => (
        'Poll expired',
        'This poll has expired and no longer accepts votes.',
      ),
      _SharedPollIssue.failed => (
        "Couldn't load this poll",
        'Something went wrong while contacting Yakku. Please try again.',
      ),
      _SharedPollIssue.alreadyVoted => (
        'You already voted',
        "You've already answered this card. Thanks for your opinion!",
      ),
      _SharedPollIssue.ownCard => (
        'This is your card',
        "You can't vote on a card you created. Share it with friends instead.",
      ),
      _SharedPollIssue.cannotVote => (
        "You can't vote on this card",
        "This card isn't open for your vote right now.",
      ),
    };
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (issue == _SharedPollIssue.failed) ...[
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
            const SizedBox(height: AppSpacing.sm),
          ],
          OutlinedButton(
            onPressed: onLeave,
            child: const Text('Back to Yakku'),
          ),
        ],
      ),
    );
  }
}
