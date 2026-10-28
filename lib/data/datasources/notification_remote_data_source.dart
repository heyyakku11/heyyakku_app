import 'package:yakku/data/models/notification/app_notification.dart';

abstract interface class NotificationRemoteDataSource {
  /// `GET /api/v1/notifications`: the signed-in user's notifications, newest
  /// first, one cursor page at a time.
  Future<NotificationsPage> getNotifications({String? cursor});

  /// `PATCH /api/v1/notifications/read-all`: marks every unread one as read.
  Future<void> markAllRead();

  /// `PATCH /api/v1/notifications/{id}/read`.
  Future<AppNotification> markRead(String id);
}
