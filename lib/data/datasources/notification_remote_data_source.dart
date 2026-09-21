import 'package:yakku/data/models/notification/notification_response.dart';

abstract interface class NotificationRemoteDataSource {
  Future<NotificationsPage> getMine({String? cursor});

  Future<NotificationResponse> markAsRead(String id);
}
