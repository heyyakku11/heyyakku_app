import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yakku/presentation/screens/inbox/open_notification_target.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/models/notification/app_notification.dart';

/// The signed-in user's notifications, loaded from the API a page at a time
/// (newest first). Pull down to refresh; more load when the end is reached.
/// Tapping a notification marks it as read.
class NotificationList extends StatefulWidget {
  const NotificationList({
    super.key,
    required this.source,
    this.header,
    this.onAskSomething,
  });

  final NotificationRemoteDataSource source;

  /// Shown under the title, above the notifications (e.g. active cards).
  final Widget? header;

  /// Called from the empty state's button (switches to the Home tab).
  final VoidCallback? onAskSomething;

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final ScrollController _scroll = ScrollController();
  List<AppNotification> _items = const [];
  String? _nextCursor;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });

    try {
      final page = await widget.source.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load notifications',
        ).message;
      });
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);

    try {
      final page = await widget.source.getNotifications(cursor: _nextCursor);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page.items];
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      // Keep what is on screen; the next scroll to the end tries again.
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _markRead(AppNotification item) async {
    if (item.isRead) return;

    void setRead(bool value) {
      setState(() {
        _items = [
          for (final current in _items)
            current.id == item.id ? current.copyWith(isRead: value) : current,
        ];
      });
    }

    setRead(true);
    try {
      await widget.source.markRead(item.id);
    } catch (_) {
      if (mounted) setRead(false);
    }
  }

  Future<void> _markAllRead() async {
    final before = _items;
    setState(() {
      _items = [for (final item in _items) item.copyWith(isRead: true)];
    });
    try {
      await widget.source.markAllRead();
    } catch (_) {
      if (mounted) setState(() => _items = before);
    }
  }

  /// Marks the notification read and opens the card's results screen.
  Future<void> _open(AppNotification item) async {
    unawaited(_markRead(item));
    final target = item.target;
    if (target == null) return;
    await openNotificationTarget(context, target);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return _Message(
        text: _error!,
        action: TextButton(onPressed: _load, child: const Text('Try again')),
      );
    }

    // Active cards are activity too: with some, there is no empty state, just
    // the title and the cards.
    if (_items.isEmpty && widget.header != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            16,
            AppSpacing.screen,
            AppSpacing.screen,
          ),
          children: [
            _Header(
              extra: widget.header,
              hasUnread: false,
              onMarkAll: _markAllRead,
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Center(child: _EmptyActivity(onAsk: widget.onAskSomething)),
                    if (widget.header != null)
                      Align(
                        alignment: Alignment.topCenter,
                        child: widget.header!,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rows = _buildRows(_items);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          16,
          AppSpacing.screen,
          AppSpacing.screen,
        ),
        itemCount: rows.length + 1 + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Header(
              extra: widget.header,
              hasUnread: _items.any((item) => !item.isRead),
              onMarkAll: _markAllRead,
            );
          }
          final rowIndex = index - 1;
          if (rowIndex >= rows.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final row = rows[rowIndex];
          if (row.group != null) return _SectionLabel(row.group!);
          final item = row.item!;
          return _NotificationTile(
            item: item,
            showDivider: row.showDivider,
            onTap: () => _open(item),
          );
        },
      ),
    );
  }
}

enum _Group {
  today('TODAY'),
  earlier('EARLIER');

  const _Group(this.label);
  final String label;
}

_Group _groupOf(DateTime createdAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final local = createdAt.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  return today.difference(day).inDays <= 0 ? _Group.today : _Group.earlier;
}

/// How long ago: "now", "2m", "1h", "3d".
String _timeLabel(DateTime createdAt) {
  final d = DateTime.now().difference(createdAt);
  if (d.inMinutes < 1) return 'now';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${(d.inDays / 7).floor()}w';
}

class _Row {
  const _Row.header(this.group) : item = null, showDivider = false;
  const _Row.item(this.item, {required this.showDivider}) : group = null;

  final _Group? group;
  final AppNotification? item;
  final bool showDivider;
}

/// Flattens the (newest first) notifications into section headers and items.
List<_Row> _buildRows(List<AppNotification> items) {
  final rows = <_Row>[];
  for (var i = 0; i < items.length; i++) {
    final group = _groupOf(items[i].createdAt);
    final isFirstInGroup = i == 0 || _groupOf(items[i - 1].createdAt) != group;
    if (isFirstInGroup) rows.add(_Row.header(group));
    final isLastInGroup =
        i == items.length - 1 || _groupOf(items[i + 1].createdAt) != group;
    rows.add(_Row.item(items[i], showDivider: !isLastInGroup));
  }
  return rows;
}

class _Header extends StatelessWidget {
  const _Header({this.extra, required this.hasUnread, required this.onMarkAll});

  final Widget? extra;
  final bool hasUnread;
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Activity',
                  style: TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              if (hasUnread)
                TextButton(
                  onPressed: onMarkAll,
                  style: TextButton.styleFrom(
                    foregroundColor: YakkuPalette.Raspberry,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          if (extra != null) ...[const SizedBox(height: 14), extra!],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.group);

  final _Group group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        group.label,
        style: const TextStyle(
          fontSize: 11.5,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w800,
          color: YakkuPalette.textSecondary,
        ),
      ),
    );
  }
}

/// The little face shown for chat-like notifications (a reply, someone asking
/// back); null for the rest.
Color? _avatarColor(AppNotification item) {
  final key = '${item.eventType} ${item.type}'.toLowerCase();
  if (key.contains('ask')) return const Color(0xFFB9DDF7);
  if (key.contains('repl') || key.contains('message')) {
    return const Color(0xFFF6B7CB);
  }
  return null;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
    required this.showDivider,
  });

  final AppNotification item;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarColor(item);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: YakkuPalette.roseBorder))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot, kept as a column so read and unread rows line up.
            SizedBox(
              width: 20,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: item.isRead
                    ? null
                    : Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: YakkuPalette.Raspberry,
                        ),
                      ),
              ),
            ),
            if (avatar != null) ...[
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatar,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [_Eye(), SizedBox(width: 5), _Eye()],
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: YakkuPalette.Ink,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: item.isRead
                          ? FontWeight.w700
                          : FontWeight.w900,
                    ),
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: YakkuPalette.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _timeLabel(item.createdAt),
              style: const TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.5,
      height: 4.5,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: YakkuPalette.Ink,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

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
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({this.onAsk});

  final VoidCallback? onAsk;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: YakkuPalette.Blush.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: YakkuPalette.Raspberry,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nothing here yet',
              style: TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'When friends answer your cards, results and reasons show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: YakkuPalette.Muted,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            if (onAsk != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: onAsk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YakkuPalette.Raspberry,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  child: const Text(
                    'Ask what’s on your mind',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
