import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/models/notification/notification_response.dart';
import 'package:yakku/presentation/app_scope.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationResponse> _items = const [];
  String? _error;
  bool _loading = true;
  bool _markingAll = false;
  bool _changed = false;

  bool get _hasUnread => _items.any((item) => !item.isRead);

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
      final page = await AppScope.of(context).notifications.getMine();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load notifications',
        ).message;
      });
    }
  }

  Future<void> _markAsRead(NotificationResponse notification) async {
    if (notification.isRead || _markingAll) return;

    try {
      final updated = await AppScope.of(
        context,
      ).notifications.markAsRead(notification.id);
      if (!mounted) return;
      setState(() {
        _changed = true;
        _items = [
          for (final item in _items)
            if (item.id == notification.id) updated else item,
        ];
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        DioErrorMapper.map(
          error,
          fallback: 'Could not mark notification as read',
        ).message,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final unread = _items
        .where((item) => !item.isRead)
        .toList(growable: false);
    if (unread.isEmpty || _markingAll) return;

    setState(() => _markingAll = true);
    final notifications = AppScope.of(context).notifications;

    try {
      for (final item in unread) {
        final updated = await notifications.markAsRead(item.id);
        if (!mounted) return;
        setState(() {
          _changed = true;
          _items = [
            for (final current in _items)
              if (current.id == item.id) updated else current,
          ];
        });
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        DioErrorMapper.map(
          error,
          fallback: 'Could not mark notifications as read',
        ).message,
      );
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _leave() {
    Navigator.of(context).pop(_changed);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notification'),
          actions: [
            TextButton(
              onPressed: _hasUnread && !_markingAll ? _markAllAsRead : null,
              child: _markingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Mark all as read'),
            ),
          ],
        ),
        body: SafeArea(child: _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _NotificationMessage(text: _error!);
    }

    if (_items.isEmpty) {
      return const _NotificationMessage(text: 'No notifications yet');
    }

    return SlidableAutoCloseBehavior(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.screen),
        children: [
          for (final notification in _items)
            _notificationTile(context, notification),
        ],
      ),
    );
  }

  Widget _notificationTile(
    BuildContext context,
    NotificationResponse notification,
  ) {
    final row = _notificationRow(context, notification);
    if (notification.isRead) return row;

    final theme = Theme.of(context);
    return Slidable(
      key: ValueKey(notification.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: (_) => _markAsRead(notification),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.done,
            label: 'Mark as read',
          ),
        ],
      ),
      child: row,
    );
  }

  Widget _notificationRow(
    BuildContext context,
    NotificationResponse notification,
  ) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: Row(
        spacing: 10,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(child: Icon(Icons.notifications)),
              if (!notification.isRead)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: titleStyle),
                if (notification.body.isNotEmpty) ...[
                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 10),
                Divider(height: 1, thickness: 1, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({required this.text});

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
