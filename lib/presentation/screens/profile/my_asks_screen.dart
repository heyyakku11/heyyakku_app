import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/poll_results_screen.dart';

enum _AskFilter { live, closed }

class MyAsksScreen extends StatefulWidget {
  const MyAsksScreen({super.key});

  @override
  State<MyAsksScreen> createState() => _MyAsksScreenState();
}

class _MyAsksScreenState extends State<MyAsksScreen> {
  _AskFilter _filter = _AskFilter.live;
  List<PollModel> _polls = const [];
  bool _loading = true;
  String? _error;

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
      final polls = await AppScope.of(context).activityPolls.getCreatedPolls();
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
          fallback: 'Could not load your asks',
        ).message;
      });
    }
  }

  Future<void> _openResults(PollModel poll) async {
    if (poll.isCheck) {
      await _openCheck(poll);
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PollResultsScreen.byPollId(pollId: poll.id),
      ),
    );
    if (!mounted || changed != true) return;
    await _load();
  }

  /// A made check opens the owner's check view, which needs the full check
  /// (colour, sticker, options), so it is loaded from the user's checks.
  Future<void> _openCheck(PollModel poll) async {
    try {
      final checks = await AppScope.of(context).checkApi.getMyChecks();
      if (!mounted) return;
      final check = checks.where((item) => item.id == poll.id).firstOrNull;
      if (check == null) {
        throw StateError('Check not found');
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PollResultsScreen.check(check: check),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = DioErrorMapper.map(
        error,
        fallback: 'Could not open this check',
      ).message;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final live = _polls.where(_isLive).toList(growable: false);
    final closed = _polls
        .where((poll) => !_isLive(poll))
        .toList(growable: false);
    final visible = _filter == _AskFilter.live ? live : closed;

    return Scaffold(
      appBar: AppBar(title: const Text('My asks'), centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                _FilterPill(
                  label: 'Live (${live.length})',
                  selected: _filter == _AskFilter.live,
                  onTap: () => setState(() => _filter = _AskFilter.live),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'Closed (${closed.length})',
                  selected: _filter == _AskFilter.closed,
                  onTap: () => setState(() => _filter = _AskFilter.closed),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(theme, visible)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, List<PollModel> visible) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    if (visible.isEmpty) {
      final label = _filter == _AskFilter.live
          ? 'No live asks'
          : 'No closed asks';
      return Center(
        child: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: visible.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _AskCard(
            poll: visible[index],
            accent: _accents[index % _accents.length],
            onTap: () => _openResults(visible[index]),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = selected
        ? (isDark ? Colors.white : const Color(0xFF111111))
        : Colors.transparent;
    final foreground = selected
        ? (isDark ? const Color(0xFF111111) : Colors.white)
        : theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _AskCard extends StatelessWidget {
  const _AskCard({
    required this.poll,
    required this.accent,
    required this.onTap,
  });

  final PollModel poll;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = _isLive(poll) ? _timeLeftLabel(poll.expiresAt) : null;
    final almost = timeLabel == 'Almost';

    return Material(
      color: theme.cardTheme.color ?? Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent,
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.question,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _votesLabel(poll.totalVoteCount),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (timeLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: almost
                        ? const Color(0xFFFFE7A3)
                        : const Color(0xFFF8D3E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: almost
                          ? const Color(0xFF8A6A12)
                          : const Color(0xFFD02E62),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _accents = <Color>[
  Color(0xFFFFE7A3),
  Color(0xFFE4D7FF),
  Color(0xFFD6E8FF),
  Color(0xFFDDF3E4),
];

bool _isLive(PollModel poll) {
  if (!poll.status.isActive) return false;
  final expiresAt = poll.expiresAt;
  if (expiresAt == null) return true;
  return expiresAt.isAfter(DateTime.now());
}

String? _timeLeftLabel(DateTime? expiresAt) {
  if (expiresAt == null) return null;
  final remaining = expiresAt.difference(DateTime.now());
  if (remaining.isNegative) return null;
  if (remaining.inMinutes < 60) return 'Almost';
  if (remaining.inHours < 24) {
    final hours = remaining.inHours == 0 ? 1 : remaining.inHours;
    return '${hours}h left';
  }
  final days = remaining.inDays == 0 ? 1 : remaining.inDays;
  return '${days}d left';
}

String _votesLabel(int count) => count == 1 ? '1 vote' : '$count votes';
