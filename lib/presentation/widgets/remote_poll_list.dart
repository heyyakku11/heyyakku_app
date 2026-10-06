import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/presentation/screens/poll_flow_args.dart';
import 'package:yakku/presentation/widgets/poll_card.dart';
import 'package:yakku/presentation/widgets/poll_owner_actions_sheet.dart';

class RemotePollList extends StatefulWidget {
  const RemotePollList({
    super.key,
    required this.loadPolls,
    required this.emptyMessage,
    this.errorFallback = 'Could not load polls',
    this.ownerActions = false,
  });

  final Future<List<PollModel>> Function() loadPolls;
  final String emptyMessage;
  final String errorFallback;
  final bool ownerActions;

  @override
  State<RemotePollList> createState() => _RemotePollListState();
}

class _RemotePollListState extends State<RemotePollList> {
  List<PollModel> _polls = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final polls = await widget.loadPolls();
      if (!mounted) return;
      setState(() {
        _polls = polls;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _polls = const [];
        _loading = false;
        _error = DioErrorMapper.map(
          error,
          fallback: widget.errorFallback,
        ).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _PollListMessage(text: _error!);
    }

    if (_polls.isEmpty) {
      return _PollListMessage(text: widget.emptyMessage);
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.screen),
      itemCount: _polls.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final poll = _polls[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openPoll(poll),
            borderRadius: BorderRadius.circular(12),
            child: PollCard(
              poll: poll,
              showMakeItYours: false,
              showVoteCount: true,
              showWhyCount: true,
              onOwnerActions: widget.ownerActions
                  ? () => _openOwnerActions(poll)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPoll(PollModel poll) async {
    if (GoRouter.maybeOf(context) == null) return;
    final extra = widget.ownerActions
        ? PollViewArgs(pollId: poll.id, canManage: true)
        : poll.id;
    final changed = await context.push<bool>(AppRoutes.pollView, extra: extra);
    if (!mounted || changed != true) return;
    await _load();
  }

  Future<void> _openOwnerActions(PollModel poll) async {
    final changed = await showPollOwnerActionsSheet(context, pollId: poll.id);
    if (!mounted || !changed) return;
    await _load();
  }
}

class _PollListMessage extends StatelessWidget {
  const _PollListMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
