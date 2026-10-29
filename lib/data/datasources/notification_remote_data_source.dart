import 'package:flutter/foundation.dart';
import 'package:yakku/data/models/notification/app_notification.dart';

abstract interface class NotificationRemoteDataSource {
  /// Ticks after notifications were marked read outside the Activity list (a
  /// card's results were opened), so the Activity badge can refresh itself.
  Listenable get readChanges;

  /// `GET /api/v1/notifications`: the signed-in user's notifications, newest
  /// first, one cursor page at a time.
  Future<NotificationsPage> getNotifications({String? cursor});

  /// `GET /api/v1/notifications/unread-count`: for the Activity tab badge.
  Future<int> getUnreadCount();

  /// `PATCH /api/v1/notifications/read-all`: marks every unread one as read.
  Future<void> markAllRead();

  /// `PATCH /api/v1/notifications/{id}/read`.
  Future<AppNotification> markRead(String id);

  /// `PATCH /api/v1/notifications/content/{contentType}/{contentId}/read`:
  /// marks every unread notification about one card (`poll` or `check`) read.
  /// Call it when the owner opens that card's results, so the answers they have
  /// seen are left out of the 30-minute digest push.
  Future<void> markContentRead(String contentType, String contentId);
}
