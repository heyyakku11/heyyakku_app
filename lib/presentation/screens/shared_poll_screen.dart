import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/check_theme.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/answer_poll_screen.dart';
import 'package:yakku/presentation/widgets/voting_closed_view.dart';

enum _SharedPollIssue {
  notFound,
  unavailable,
  closed,
  expired,
  failed,
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
  static const _pollTheme = CheckTheme(
    heading: '',
    backgroundColor: YakkuPalette.cream,
    headingColor: YakkuPalette.textPrimary,
    questionColor: YakkuPalette.textPrimary,
    accentColor: YakkuPalette.primary,
    stickerLabel: '',
    stickerColor: YakkuPalette.primary,
    optionBackgroundColor: YakkuPalette.white,
    optionTextColor: YakkuPalette.textPrimary,
  );

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
        // Keep the poll for closed/expired so the edge template can preview it.
        _poll = issue == null ||
                issue == _SharedPollIssue.closed ||
                issue == _SharedPollIssue.expired
            ? poll
            : null;
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
    // Owner always sees their own card flow, even when the card is closed.
    if (poll.isOwner) return null;

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
    // An already-voted card is shown by AnswerPollScreen with the voter's pick.
    if (voting.hasVoted) return null;
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

  CheckTheme get _theme => _poll?.checkTheme ?? _pollTheme;

  static String _span(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    return '${d.inMinutes.clamp(1, 59)}m';
  }

  String? _closedLabel(PollResponse poll, {required bool expired}) {
    final now = DateTime.now();
    final when = poll.closedAt ??
        (poll.expiresAt != null && !poll.expiresAt!.isAfter(now)
            ? poll.expiresAt
            : null);
    if (when == null) return expired ? 'Expired' : 'Closed';
    final age = now.difference(when);
    if (age.isNegative || age.inMinutes < 1) {
      return expired ? 'Expired just now' : 'Closed just now';
    }
    final span = _span(age);
    return expired ? 'Expired $span ago' : 'Closed $span ago';
  }

  @override
  Widget build(BuildContext context) {
    final poll = _poll;
    final issue = _issue;

    if (poll != null && issue == null) {
      return AnswerPollScreen(poll: poll);
    }

    if (poll != null &&
        (issue == _SharedPollIssue.closed ||
            issue == _SharedPollIssue.expired)) {
      return _buildVotingClosed(poll, expired: issue == _SharedPollIssue.expired);
    }

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

  Widget _buildVotingClosed(PollResponse poll, {required bool expired}) {
    final theme = _theme;
    final heading = theme.heading.trim();
    final sticker = theme.stickerLabel.trim();

    Widget? header;
    if (heading.isNotEmpty || sticker.isNotEmpty) {
      header = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: heading.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      heading,
                      style: TextStyle(
                        color: theme.headingColor,
                        fontSize: 34,
                        height: 1.02,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
          ),
          if (sticker.isNotEmpty) ...[
            const SizedBox(width: 12),
            _StickerBanner(text: sticker, color: theme.stickerColor),
          ],
        ],
      );
    }

    return Scaffold(
      body: VotingClosedView(
        key: ValueKey(expired ? 'voting-closed-expired' : 'voting-closed'),
        onLeave: _leave,
        onClose: _leave,
        accentColor: theme.accentColor,
        background: BoxDecoration(color: theme.backgroundColor),
        title: expired ? 'This card expired' : VotingClosedView.defaultTitle,
        subtitle: expired
            ? 'Voting ended when the timer ran out.'
            : VotingClosedView.defaultSubtitle,
        statusLabel: _closedLabel(poll, expired: expired),
        header: header,
        preview: DecoratedBox(
          decoration: BoxDecoration(
            color: YakkuPalette.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.accentColor.withValues(alpha: 0.18)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  poll.question,
                  style: TextStyle(
                    color: theme.questionColor,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < poll.options.length; i++) ...[
                  _ClosedOptionRow(
                    letter: String.fromCharCode(65 + i),
                    text: poll.options[i].text ?? '',
                    theme: theme,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerBanner extends StatelessWidget {
  const _StickerBanner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: YakkuPalette.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: YakkuPalette.textPrimary),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pacifico',
              color: color,
              fontSize: 15,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClosedOptionRow extends StatelessWidget {
  const _ClosedOptionRow({
    required this.letter,
    required this.text,
    required this.theme,
  });

  final String letter;
  final String text;
  final CheckTheme theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.optionBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YakkuPalette.roseBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: TextStyle(
                  color: theme.optionTextColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.optionTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
    // Closed / expired always use the designed template, never plain text.
    if (issue == _SharedPollIssue.closed || issue == _SharedPollIssue.expired) {
      return VotingClosedView(
        onLeave: onLeave,
        onClose: onLeave,
        title: issue == _SharedPollIssue.expired
            ? 'This card expired'
            : VotingClosedView.defaultTitle,
        subtitle: issue == _SharedPollIssue.expired
            ? 'Voting ended when the timer ran out.'
            : VotingClosedView.defaultSubtitle,
        statusLabel: issue == _SharedPollIssue.expired ? 'Expired' : 'Closed',
      );
    }

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
        VotingClosedView.defaultTitle,
        VotingClosedView.defaultSubtitle,
      ),
      _SharedPollIssue.expired => (
        'This card expired',
        'Voting ended when the timer ran out.',
      ),
      _SharedPollIssue.failed => (
        "Couldn't load this poll",
        'Something went wrong while contacting Yakku. Please try again.',
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
