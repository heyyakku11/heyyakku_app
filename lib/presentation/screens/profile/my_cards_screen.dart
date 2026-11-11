import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/utils/hex_color.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/repositories/personality_card_store.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/personality/personality_navigation.dart';
import 'package:yakku/presentation/screens/profile/open_own_card.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';
import 'package:yakku/presentation/screens/profile/widgets/my_card_menu.dart';
import 'package:yakku/presentation/screens/profile/widgets/my_cards_empty_state.dart';
import 'package:yakku/presentation/screens/share/open_card_share.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

enum _Tab { all, live, closed, saved }

enum _Kind { ownCard, personality, saved }

/// One row of the list, whatever it came from.
class _Item {
  const _Item({
    required this.kind,
    required this.id,
    required this.question,
    required this.label,
    required this.color,
    required this.live,
    required this.chip,
    required this.meta,
    required this.statusLine,
    this.urgent = false,
    this.done = false,
    this.poll,
    this.saved,
    this.personality,
  });

  final _Kind kind;
  final String id;
  final String question;
  final String label;
  final Color color;
  final bool live;

  /// "Live · 18h left", "Closes in 2h", "Closed 3d ago", "Done".
  final String chip;
  final bool urgent;
  final bool done;

  /// "7 votes · result ready".
  final String meta;

  /// The one-line summary under the question in the "..." menu.
  final String statusLine;

  final PollModel? poll;
  final PollResponse? saved;
  final PersonalityCard? personality;

  bool get canShare =>
      live && (kind == _Kind.ownCard || kind == _Kind.personality);
  bool get hasMenu => kind != _Kind.personality;
}

/// The user's cards: the ones they made (live and closed) and the ones they
/// saved, with a "..." menu on each to close, delete or unsave.
class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  static const _pollColor = Color(0xFFEAF6C6);

  _Tab _tab = _Tab.all;
  List<_Item> _items = const [];
  bool _loading = true;
  String? _error;
  List<PollModel> _polls = const [];
  List<PollResponse> _savedPolls = const [];
  PersonalityCardStore? _store;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = AppScope.of(context).personalityCards;
    if (!identical(_store, store)) {
      _store?.removeListener(_onCardChanged);
      _store = store..addListener(_onCardChanged);
    }
  }

  @override
  void dispose() {
    _store?.removeListener(_onCardChanged);
    super.dispose();
  }

  /// The personality card changed somewhere (draft to collecting, a vote, done):
  /// rebuild its row here too.
  void _onCardChanged() {
    if (!mounted || _loading) return;
    setState(() => _items = _buildItems(_polls, _savedPolls, _store?.card));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  List<_Item> get _live => [
    for (final i in _items)
      if (i.kind != _Kind.saved && i.live) i,
  ];
  List<_Item> get _closed => [
    for (final i in _items)
      if (i.kind != _Kind.saved && !i.live) i,
  ];
  List<_Item> get _saved => [
    for (final i in _items)
      if (i.kind == _Kind.saved) i,
  ];

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    final scope = AppScope.of(context);
    try {
      final polls = await scope.activityPolls.getCreatedPolls();
      // Saved cards and the personality card are extras: a failure there
      // must not hide the user's own cards.
      final saved = await _loadSaved(scope.userRemote);
      // The personality card comes from the shared store, which keeps it fresh.
      unawaited(scope.personalityCards.refresh());
      if (!mounted) return;
      setState(() {
        _polls = polls;
        _savedPolls = saved;
        _items = _buildItems(polls, saved, scope.personalityCards.card);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load your cards',
        ).message;
      });
    }
  }

  Future<List<PollResponse>> _loadSaved(UserRemoteDataSource remote) async {
    final items = <PollResponse>[];
    try {
      String? cursor;
      final seen = <String>{};
      while (true) {
        final page = await remote.getSavedPolls(cursor: cursor);
        items.addAll(page.items);
        final next = page.nextCursor;
        if (!page.hasMore || next == null || next.isEmpty || !seen.add(next)) {
          break;
        }
        cursor = next;
      }
    } catch (_) {}
    return items;
  }

  List<_Item> _buildItems(
    List<PollModel> polls,
    List<PollResponse> saved,
    PersonalityCard? personality,
  ) {
    final now = DateTime.now();
    final items = <_Item>[];

    if (personality != null &&
        personality.status != PersonalityCardStatus.draft) {
      final done = personality.isCompleted;
      items.add(
        _Item(
          kind: _Kind.personality,
          id: 'personality',
          question: 'Describe me in 3 words',
          label: 'WHO YOU ARE',
          color: YakkuPalette.Raspberry,
          live: !done,
          chip: done ? 'Done' : 'Live',
          done: done,
          meta: done
              ? '${personality.totalVotes} friends · top 3 ready'
              : '${personality.totalVotes} of ${personality.requiredVotes} friends',
          statusLine: '',
          personality: personality,
        ),
      );
    }

    for (final poll in polls) {
      final live = _isLive(poll, now);
      final left = poll.expiresAt?.difference(now);
      final urgent = live && left != null && left.inMinutes < 180;
      items.add(
        _Item(
          kind: _Kind.ownCard,
          id: poll.id,
          question: poll.question,
          label: poll.isCheck
              ? (poll.checkTitle ?? 'CHECK').toUpperCase()
              : 'YOUR QUESTION',
          color: poll.isCheck
              ? parseHexColor(poll.checkColor, fallback: _pollColor)
              : _pollColor,
          live: live,
          urgent: urgent,
          chip: live
              ? (urgent
                    ? 'Closes in ${_short(left)}'
                    : left == null
                    ? 'Live'
                    : 'Live · ${_short(left)} left')
              : (poll.closedAt == null
                    ? 'Closed'
                    : 'Closed ${_ago(now.difference(poll.closedAt!))}'),
          meta: _votes(poll, live),
          statusLine: [
            _votes(poll, live),
            if (live && left != null) 'closes in ${_short(left)}',
          ].join(' · '),
          poll: poll,
        ),
      );
    }

    for (final poll in saved) {
      final live =
          poll.status.toLowerCase() == 'active' &&
          (poll.expiresAt == null || poll.expiresAt!.isAfter(now));
      final left = poll.expiresAt?.difference(now);
      items.add(
        _Item(
          kind: _Kind.saved,
          id: poll.id,
          question: poll.question,
          label: 'SAVED',
          color: YakkuPalette.white,
          live: live,
          chip: live
              ? (left == null ? 'Live' : 'Live · ${_short(left)} left')
              : 'Closed',
          meta: poll.totalVoteCount == 1
              ? '1 vote'
              : '${poll.totalVoteCount} votes',
          statusLine: 'Saved card',
          saved: poll,
        ),
      );
    }
    return items;
  }

  bool _isLive(PollModel poll, DateTime now) {
    if (!poll.status.isActive) return false;
    final expiresAt = poll.expiresAt;
    return expiresAt == null || expiresAt.isAfter(now);
  }

  String _votes(PollModel poll, bool live) {
    final progress = poll.voteProgress;
    if (poll.totalVoteCount == 0 && progress == 0) return 'No votes yet';
    if (poll.resultsUnlocked) {
      final total = '${poll.totalVoteCount} votes';
      return live ? '$total · result ready' : total;
    }
    if (live) return '$progress of ${poll.minVotes} votes';
    return '$progress ${progress == 1 ? 'vote' : 'votes'} · not enough for a result';
  }

  String _short(Duration? d) {
    if (d == null || d.isNegative) return '0m';
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    return '${d.inMinutes.clamp(1, 59)}m';
  }

  String _ago(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    final m = d.inMinutes;
    return m < 1 ? 'just now' : '${m}m ago';
  }

  // ---- actions ----------------------------------------------------------

  Future<void> _open(_Item item) async {
    switch (item.kind) {
      case _Kind.ownCard:
        await _openResults(item.poll!);
      case _Kind.saved:
        await context.push(AppRoutes.pollVoteLocation(item.saved!.shareCode));
        if (mounted) await _load();
      case _Kind.personality:
        final changed = await openPersonalityAsk(
          context,
          item.personality!,
          AppScope.of(context).personalityCards.traits,
        );
        if (changed && mounted) await _load();
    }
  }

  Future<void> _openResults(PollModel poll) async {
    final changed = await openOwnCardResults(context, poll);
    if (mounted && changed) await _load();
  }

  Future<void> _share(_Item item) async {
    if (item.kind == _Kind.personality) {
      await _open(item);
      return;
    }
    final poll = item.poll!;
    await openCardShare(
      context,
      shareCode: poll.shareCode,
      title: poll.isCheck ? (poll.checkTitle ?? '') : '',
      question: poll.question,
      options: [for (final o in poll.options) o.text ?? ''],
      minVotes: poll.minVotes,
    );
  }

  Future<void> _menu(_Item item) async {
    final own = item.kind == _Kind.ownCard;
    final action = await showMyCardMenu(
      context,
      question: item.question,
      status: item.statusLine,
      canClose: own && item.live,
      canDelete: own,
      canUnsave: item.kind == _Kind.saved,
    );
    if (action == null || !mounted) return;

    switch (action) {
      case MyCardAction.close:
        final ok = await showAppConfirmDialog(
          context,
          title: 'Close this card?',
          message: 'People will no longer be able to answer it. Results stay.',
          confirmLabel: 'Close',
          cancelLabel: 'Cancel',
        );
        if (ok != true || !mounted) return;
        await _run(
          'Could not close the card',
          (scope) => item.poll!.isCheck
              ? scope.checkApi.closeMyCheck(item.id)
              : scope.userRemote.closePoll(item.id),
        );
      case MyCardAction.delete:
        if (!await showDeleteCardDialog(context, item.question) || !mounted) {
          return;
        }
        await _run(
          'Could not delete the card',
          (scope) => item.poll!.isCheck
              ? scope.checkApi.deleteMyCheck(item.id)
              : scope.userRemote.deletePoll(item.id),
        );
      case MyCardAction.unsave:
        await _run(
          'Could not unsave the card',
          (scope) => scope.userRemote.unsavePoll(item.id),
        );
    }
  }

  Future<void> _run(
    String failure,
    Future<Object?> Function(AppScope scope) run,
  ) async {
    try {
      await run(AppScope.of(context));
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      AppToast.show(DioErrorMapper.map(error, fallback: failure).message);
    }
  }

  // ---- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final live = _live;
    final closed = _closed;
    final saved = _saved;
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
              icon: const FaIcon(
                FontAwesomeIcons.chevronLeft,
                size: 16,
                color: YakkuPalette.Ink,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(
                'My cards',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final t in _Tab.values) ...[
                    _TabPill(
                      label: switch (t) {
                        _Tab.all => 'All',
                        _Tab.live => 'Live',
                        _Tab.closed => 'Closed',
                        _Tab.saved => 'Saved',
                      },
                      count: switch (t) {
                        _Tab.all => live.length + closed.length + saved.length,
                        _Tab.live => live.length,
                        _Tab.closed => closed.length,
                        _Tab.saved => saved.length,
                      },
                      selected: _tab == t,
                      onTap: () => setState(() => _tab = t),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _body(live, closed, saved)),
          ],
        ),
      ),
    );
  }

  Widget _body(List<_Item> live, List<_Item> closed, List<_Item> saved) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }

    final sections = <(String, List<_Item>)>[
      if (_tab == _Tab.all || _tab == _Tab.live) ('LIVE', live),
      if (_tab == _Tab.all || _tab == _Tab.closed) ('CLOSED', closed),
      if (_tab == _Tab.all || _tab == _Tab.saved) ('SAVED', saved),
    ].where((s) => s.$2.isNotEmpty).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: sections.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                MyCardsEmptyState(
                  kind: switch (_tab) {
                    _Tab.all => MyCardsEmptyKind.all,
                    _Tab.live => MyCardsEmptyKind.live,
                    _Tab.closed => MyCardsEmptyKind.closed,
                    _Tab.saved => MyCardsEmptyKind.saved,
                  },
                  onAction: () => showCreatePollSheet(context),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
              children: [
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 0, 10),
                    child: Text(
                      '${section.$1} · ${section.$2.length}',
                      style: const TextStyle(
                        color: YakkuPalette.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (final item in section.$2) ...[
                    _CardTile(
                      item: item,
                      onTap: () => _open(item),
                      onMenu: item.hasMenu ? () => _menu(item) : null,
                      onShare: item.canShare ? () => _share(item) : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ],
            ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? YakkuPalette.Ink : YakkuPalette.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? YakkuPalette.Ink : YakkuPalette.roseBorder,
          ),
        ),
        child: Text(
          '$label $count',
          style: TextStyle(
            color: selected ? YakkuPalette.white : YakkuPalette.Ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.item,
    required this.onTap,
    this.onMenu,
    this.onShare,
  });

  final _Item item;
  final VoidCallback onTap;
  final VoidCallback? onMenu;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final dark = item.color.computeLuminance() < 0.35;
    final text = dark ? YakkuPalette.white : YakkuPalette.Ink;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YakkuPalette.Ink, width: 1.5),
          boxShadow: const [
            BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text.withValues(alpha: 0.75),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (onMenu != null)
                  GestureDetector(
                    onTap: onMenu,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 22,
                        color: text,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.question,
              style: TextStyle(
                color: text,
                fontSize: 18,
                height: 1.15,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Chip(item: item),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onShare != null)
                  GestureDetector(
                    onTap: onShare,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FaIcon(
                        FontAwesomeIcons.share,
                        size: 16,
                        color: text,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    final urgent = item.urgent;
    final color = urgent ? YakkuPalette.Error : YakkuPalette.Ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFFFE3E0)
            : YakkuPalette.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (urgent)
            Icon(Icons.schedule_rounded, size: 12, color: color)
          else if (item.live)
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2E9E5B),
              ),
            ),
          if (urgent || item.live) const SizedBox(width: 5),
          Text(
            item.chip,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
