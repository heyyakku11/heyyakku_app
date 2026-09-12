import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/data/repositories/dummy_activity_poll_repository.dart';
import 'package:yakku/presentation/widgets/app_segmented_control.dart';
import 'package:yakku/presentation/widgets/poll_card.dart';

enum _ActivityTab { asked, answered }

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, this.repository});

  final ActivityPollRepository? repository;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late final ActivityPollRepository _repository =
      widget.repository ?? const DummyActivityPollRepository();

  bool _isLoading = true;
  Object? _error;
  _ActivityTab _selectedTab = _ActivityTab.asked;
  List<PollModel> _createdPolls = const [];
  List<PollModel> _answeredPolls = const [];

  @override
  void initState() {
    super.initState();
    _fetchActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _fetchActivity();
  }

  Future<void> _fetchActivity() async {
    try {
      final created = await _repository.getCreatedPolls();
      final answered = await _repository.getAnsweredPolls();
      if (!mounted) return;
      setState(() {
        _createdPolls = created;
        _answeredPolls = answered;
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _createdPolls = const [];
        _answeredPolls = const [];
        _error = error;
        _isLoading = false;
      });
    }
  }

  List<PollModel> get _visiblePolls {
    return _selectedTab == _ActivityTab.asked
        ? _createdPolls
        : _answeredPolls;
  }

  String get _emptyMessage {
    return _selectedTab == _ActivityTab.asked
        ? 'No polls asked yet'
        : 'No polls answered yet';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load activity.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _loadActivity,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

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
      child: PollCard(poll: poll, showMakeItYours: false),
    );
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
