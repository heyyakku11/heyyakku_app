import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/models/saved/saved_card.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/dashboard.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/skeleton.dart';

/// Everything the user saved, fun cards and other people's polls together, newest saved first. Each card shows what
/// it is, its question, a hint of its answers, when it was saved and a button to ask (or answer) it. The bookmark
/// at the top right removes it from the list.
class SavedPollsScreen extends StatefulWidget {
  const SavedPollsScreen({super.key});

  @override
  State<SavedPollsScreen> createState() => _SavedPollsScreenState();
}

class _SavedPollsScreenState extends State<SavedPollsScreen> {
  List<SavedCardItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final items = await _loadAllSavedCards(AppScope.of(context).userRemote);
      if (!mounted) return;
      setState(() {
        // Fun cards the user has already made into their own are not offered again, the same as on Home.
        _items = [
          for (final item in items)
            if (item.poll != null || !(item.funCard?.used ?? false)) item,
        ];
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load your saved questions',
        ).message;
        _loading = false;
      });
    }
  }

  void _browse() {
    // Back to the dashboard, on its Home tab.
    Navigator.of(context).popUntil((route) => route.isFirst);
    DashboardTabs.showHome();
  }

  /// Ask a fun card, or open another person's poll to answer it.
  Future<void> _open(SavedCardItem item) async {
    final fun = item.funCard;
    if (fun != null) {
      openAskFriendsCheck(
        context,
        AskFriendsCheck.fromMirrorCheck(
          MirrorCheck.fromCheck(fun, isFun: true),
        ),
      );
      return;
    }
    final poll = item.poll;
    if (poll != null) {
      await context.push(AppRoutes.pollVoteLocation(poll.shareCode));
      if (mounted) await _load();
    }
  }

  /// Removes the card from the list at once; if the request fails it comes back and a toast says why.
  Future<void> _unsave(SavedCardItem item) async {
    final before = _items;
    setState(
      () => _items = [
        for (final i in before)
          if (i != item) i,
      ],
    );
    try {
      final scope = AppScope.of(context);
      if (item.type == SavedCardType.funCard) {
        await scope.checkApi.setFunCardSaved(item.cardId, saved: false);
      } else {
        await scope.userRemote.unsavePoll(item.cardId);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _items = before);
      AppToast.show(
        DioErrorMapper.map(
          error,
          fallback: 'Could not remove it from your saved questions',
        ).message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              padding: EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                'Saved questions',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(
                'Questions you saved to ask later.',
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const _SavedSkeleton();

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [_SavedEmptyState(onBrowse: _browse)],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'SAVED · ${_items.length}',
                    style: const TextStyle(
                      color: YakkuPalette.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                for (final item in _items) ...[
                  _SavedCardTile(
                    item: item,
                    onOpen: () => _open(item),
                    onUnsave: () => _unsave(item),
                  ),
                  const SizedBox(height: 16),
                ],
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Save any question from its preview on Home and it '
                    'shows up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: YakkuPalette.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// One saved card: what it is, the question, a hint of the answers, when it was saved, and a button to ask it.
class _SavedCardTile extends StatelessWidget {
  const _SavedCardTile({
    required this.item,
    required this.onOpen,
    required this.onUnsave,
  });

  final SavedCardItem item;
  final VoidCallback onOpen;
  final VoidCallback onUnsave;

  static const _ink = YakkuPalette.Ink;

  @override
  Widget build(BuildContext context) {
    final fun = item.funCard;
    final poll = item.poll;

    final String tag;
    final String question;
    final String hint;
    final Color background;
    final Color tagColor;
    final String action;

    if (fun != null) {
      final card = MirrorCheck.fromCheck(fun, isFun: true);
      final options = [
        for (final option in card.options)
          if (option.label.trim().isNotEmpty) option.label.trim(),
      ];
      tag = card.title;
      question = card.question.isNotEmpty ? card.question : card.title;
      hint = '${options.length} options · ${options.join(', ')}';
      background = card.backgroundColor;
      tagColor = card.foregroundColor;
      action = 'Ask now';
    } else {
      final options = [...?poll?.options]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final texts = [
        for (final option in options)
          if ((option.text ?? '').trim().isNotEmpty) option.text!.trim(),
      ];
      tag = 'POLL';
      question = poll?.question ?? '';
      hint = texts.length >= 2
          ? '${texts.length} options · from “${texts.first}” to “${texts.last}”'
          : '${texts.length} options';
      background = YakkuPalette.mint;
      tagColor = YakkuPalette.successGreen;
      action = 'Answer';
    }

    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _ink, width: 1.5),
          boxShadow: const [BoxShadow(color: _ink, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tag.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                // Filled bookmark: it is saved. Tapping it removes it.
                IconButton(
                  onPressed: onUnsave,
                  tooltip: 'Remove from saved',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 36,
                  ),
                  icon: const Icon(
                    Icons.bookmark_rounded,
                    size: 24,
                    color: _ink,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                question,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tagColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _savedAgo(item.savedAt),
                      style: TextStyle(
                        color: _ink.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: YakkuPalette.white,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _savedAgo(DateTime? savedAt) {
    if (savedAt == null) return 'Saved';
    final d = DateTime.now().difference(savedAt.toLocal());
    if (d.inDays >= 1) return 'Saved ${d.inDays}d ago';
    if (d.inHours >= 1) return 'Saved ${d.inHours}h ago';
    final m = d.inMinutes;
    return m < 1 ? 'Saved just now' : 'Saved ${m}m ago';
  }
}

/// The list while it loads: the "SAVED" label and two card-shaped blocks.
class _SavedSkeleton extends StatelessWidget {
  const _SavedSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: const [
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(width: 70, height: 12, radius: 6),
            ),
          ),
          SkeletonBox(height: 168, radius: 22),
          SizedBox(height: 16),
          SkeletonBox(height: 168, radius: 22),
        ],
      ),
    );
  }
}

/// Shown while the user has not saved any question yet.
class _SavedEmptyState extends StatelessWidget {
  const _SavedEmptyState({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: YakkuPalette.pinkWash,
            ),
            child: const FaIcon(
              FontAwesomeIcons.bookmark,
              size: 28,
              color: YakkuPalette.Raspberry,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Nothing saved yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap a question on Home to preview it, then tap Save. It waits '
            'here until you’re ready to ask.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onBrowse,
            style: FilledButton.styleFrom(
              backgroundColor: YakkuPalette.Ink,
              foregroundColor: YakkuPalette.white,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Browse questions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every saved card, all pages, polls and fun cards together (the API keeps one list for both).
Future<List<SavedCardItem>> _loadAllSavedCards(
  UserRemoteDataSource remote,
) async {
  final items = <SavedCardItem>[];
  String? cursor;
  final seenCursors = <String>{};

  while (true) {
    final page = await remote.getSavedCards(cursor: cursor);
    items.addAll(page.items);
    final next = page.nextCursor;
    if (!page.hasMore ||
        next == null ||
        next.isEmpty ||
        !seenCursors.add(next)) {
      break;
    }
    cursor = next;
  }

  return items;
}
