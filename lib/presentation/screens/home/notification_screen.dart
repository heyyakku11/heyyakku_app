import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/models/notification/notification_response.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static final List<NotificationResponse> _dummyNotifications = [
    NotificationResponse(
      id: 'n1',
      type: 'poll',
      eventType: 'vote',
      title: 'Someone voted on your poll',
      body: 'A friend answered your question.',
      isRead: false,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    NotificationResponse(
      id: 'n2',
      type: 'poll',
      eventType: 'comment',
      title: 'New activity on your poll',
      body: 'Your poll is getting more answers.',
      isRead: true,
      createdAt: DateTime.utc(2026, 1, 2),
    ),
    NotificationResponse(
      id: 'n3',
      type: 'poll',
      eventType: 'comment',
      title: 'New activity on your poll',
      body: 'Your poll is getting more answers.',
      isRead: true,
      createdAt: DateTime.utc(2026, 1, 2),
    ),
    NotificationResponse(
      id: 'n4',
      type: 'poll',
      eventType: 'comment',
      title: 'New activity on your poll',
      body: 'Your poll is getting more answers.',
      isRead: true,
      createdAt: DateTime.utc(2026, 1, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final notifications = _dummyNotifications;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.screen),
      children: notifications.isEmpty
          ? const [_NotificationMessage(text: 'No notifications yet')]
          : notifications
                .map((notification) => _notificationRow(context, notification))
                .toList(growable: false),
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
              const CircleAvatar(child: Icon(Icons.notification_important)),

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
