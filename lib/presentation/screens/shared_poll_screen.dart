import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/answer_poll_screen.dart';

enum _SharedPollIssue { notFound, unavailable, closed, expired, failed }

/// Destination of `https://<web host>/vote/{shareCode}` links. Loads the poll
/// through the share-code poll API and hands it to [AnswerPollScreen].
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    if (!PollDeepLink.isValidShareCode(widget.shareCode)) {
      setState(() => _issue = _SharedPollIssue.notFound);
      return;
    }
    setState(() {
      _poll = null;
      _issue = null;
    });
    final repo = AppScope.of(context).pollApi;
    try {
      final poll = await repo.getPollByShareCode(widget.shareCode);
      if (!mounted) return;
      final issue = _issueFor(poll);
      setState(() {
        _issue = issue;
        _poll = issue == null ? poll : null;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final status = error.response?.statusCode;
      setState(() {
        _issue = switch (status) {
          400 || 404 => _SharedPollIssue.notFound,
          401 || 403 => _SharedPollIssue.unavailable,
          _ => _SharedPollIssue.failed,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _issue = _SharedPollIssue.failed);
    }
  }

  /// UI-level hint only; the backend remains the authority on vote validity.
  _SharedPollIssue? _issueFor(PollResponse poll) {
    if (poll.id.isEmpty || poll.options.isEmpty) {
      return _SharedPollIssue.notFound;
    }
    if (poll.visibility.toLowerCase() != 'public') {
      return _SharedPollIssue.unavailable;
    }
    final status = poll.status.toLowerCase();
    if (status == 'closed') return _SharedPollIssue.closed;
    if (status == 'expired') return _SharedPollIssue.expired;
    if (status != 'active') return _SharedPollIssue.unavailable;
    final expiresAt = poll.expiresAt;
    if (expiresAt != null && !expiresAt.isAfter(DateTime.now())) {
      return _SharedPollIssue.expired;
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
