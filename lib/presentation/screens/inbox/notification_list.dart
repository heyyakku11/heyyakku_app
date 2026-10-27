import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/models/notification/app_notification.dart';

/// The signed-in user's notifications, loaded from the API a page at a time
/// (newest first). Pull down to refresh; more load when the end is reached.
/// Tapping a notification marks it as read.
class NotificationList extends StatefulWidget {
  const NotificationList({super.key, required this.source});

  final NotificationRemoteDataSource source;

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

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: const _Message(text: 'No notifications yet'),
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
          if (index == 0) return const _Header();
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
            onTap: () => _markRead(item),
          );
        },
      ),
    );
  }
}

enum _Group {
  today('Today'),
  yesterday('Yesterday'),
  earlier('Earlier');

  const _Group(this.label);
  final String label;
}

_Group _groupOf(DateTime createdAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final local = createdAt.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return _Group.today;
  if (days == 1) return _Group.yesterday;
  return _Group.earlier;
}

/// Clock time for Today and Yesterday (e.g. "3:45 PM"); the date for older ones.
String _timeLabel(DateTime createdAt) {
  final local = createdAt.toLocal();
  if (_groupOf(createdAt) == _Group.earlier) {
    return '${local.day}/${local.month}/${local.year}';
  }
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Center(
        child: Text(
          'Activity',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
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
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        group.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Style {
  const _Style(this.icon, this.background);

  final IconData icon;
  final Color background;
}

/// Icon and pastel tint for a notification, picked from its event type.
_Style _styleOf(AppNotification item) {
  final key = '${item.eventType} ${item.type}'.toLowerCase();
  if (key.contains('ready') || key.contains('result')) {
    return const _Style(Icons.check_rounded, Color(0xFFFFDFE8));
  }
  if (key.contains('vote')) {
    return const _Style(Icons.people_alt_outlined, YakkuPalette.accentYellow);
  }
  if (key.contains('option')) {
    return const _Style(Icons.edit_outlined, YakkuPalette.accentPurple);
  }
  return const _Style(
    Icons.chat_bubble_outline_rounded,
    YakkuPalette.accentGreen,
  );
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
    final theme = Theme.of(context);
    final style = _styleOf(item);
    final ink = YakkuPalette.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: theme.dividerColor))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.background,
              ),
              child: Icon(style.icon, size: 22, color: ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: item.isRead
                          ? FontWeight.w600
                          : FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    _timeLabel(item.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: YakkuPalette.primaryBright,
                ),
              ),
          ],
        ),
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
