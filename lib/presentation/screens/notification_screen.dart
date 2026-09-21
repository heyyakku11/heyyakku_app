import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/models/notification/notification_response.dart';
import 'package:yakku/presentation/app_scope.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, this.dataSource});

  /// Optional override for tests. Production uses [AppScope.notifications].
  final NotificationRemoteDataSource? dataSource;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationRemoteDataSource? _dataSource;
  bool _isLoading = true;
  Object? _error;
  List<NotificationResponse> _notifications = const [];
  bool _hasRequestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dataSource ??= widget.dataSource ?? AppScope.of(context).notifications;
    if (!_hasRequestedLoad) {
      _hasRequestedLoad = true;
      _fetchNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final dataSource = _dataSource;
    if (dataSource == null) return;

    try {
      final page = await dataSource.getMine();
      if (!mounted) return;
      setState(() {
        _notifications = page.items;
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _notifications = const [];
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
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
                'Could not load notifications.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: _loadNotifications,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.screen),
        children: _notifications.isEmpty
            ? const [_NotificationMessage(text: 'No notifications yet')]
            : _notifications.map(_notificationRow).toList(growable: false),
      ),
    );
  }

  Widget _notificationRow(NotificationResponse notification) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.title, style: titleStyle),
          if (notification.body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              notification.body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
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
