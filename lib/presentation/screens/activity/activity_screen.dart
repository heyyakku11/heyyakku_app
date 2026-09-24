import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/data/datasources/poll_list_datasource.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/presentation/widgets/app_segmented_control.dart';
import 'package:yakku/presentation/widgets/poll_card.dart';

enum _ActivityTab { asked, answered }

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  _ActivityTab _selectedTab = _ActivityTab.asked;
  late final List<PollModel> _createdPolls;
  late final List<PollModel> _answeredPolls;

  @override
  void initState() {
    super.initState();
    final polls = const PollListDataSource().fetchActivePolls();
    final midpoint = (polls.length / 2).ceil();
    _createdPolls = polls.take(midpoint).toList(growable: false);
    _answeredPolls = polls.skip(midpoint).toList(growable: false);
  }

  List<PollModel> get _visiblePolls {
    return _selectedTab == _ActivityTab.asked ? _createdPolls : _answeredPolls;
  }

  String get _emptyMessage {
    return _selectedTab == _ActivityTab.asked
        ? 'No polls asked yet'
        : 'No polls answered yet';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: _buildBody()));
  }

  Widget _buildBody() {
    final polls = _visiblePolls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          child: AppSegmentedControl<_ActivityTab>(
            value: _selectedTab,
            segments: const [
              AppSegment(value: _ActivityTab.asked, label: 'Asked'),
              AppSegment(value: _ActivityTab.answered, label: 'Answered'),
            ],
            onChanged: (tab) => setState(() => _selectedTab = tab),
          ),
        ),
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.screen),
            children: polls.isEmpty
                ? [_ActivityMessage(text: _emptyMessage)]
                : polls.map(_pollCard).toList(growable: false),
          ),
        ),
      ],
    );
  }

  Widget _pollCard(PollModel poll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPoll(poll),
          borderRadius: BorderRadius.circular(12),
          child: PollCard(
            poll: poll,
            showMakeItYours: false,
            showVoteCount: true,
            showWhyCount: true,
          ),
        ),
      ),
    );
  }

  void _openPoll(PollModel poll) {
    if (GoRouter.maybeOf(context) == null) return;
    context.push(AppRoutes.pollView, extra: poll.id);
  }
}

class _ActivityMessage extends StatelessWidget {
  const _ActivityMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
