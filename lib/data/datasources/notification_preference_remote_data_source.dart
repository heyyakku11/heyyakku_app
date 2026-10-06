import 'package:yakku/data/models/notification/notification_preference_response.dart';
import 'package:yakku/data/models/notification/update_notification_preference_request.dart';

abstract interface class NotificationPreferenceRemoteDataSource {
  Future<NotificationPreferenceResponse> getPreferences();

  Future<NotificationPreferenceResponse> updatePreferences(
    UpdateNotificationPreferenceRequest request,
  );
}
