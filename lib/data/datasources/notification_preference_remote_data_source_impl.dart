import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/notification_preference_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/notification/notification_preference_response.dart';
import 'package:yakku/data/models/notification/update_notification_preference_request.dart';

class NotificationPreferenceRemoteDataSourceImpl
    implements NotificationPreferenceRemoteDataSource {
  NotificationPreferenceRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<NotificationPreferenceResponse> getPreferences() async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.notificationPreferences,
    );

    return _unwrap(
      response.data,
      emptyMessage: 'Empty notification preferences response',
      failureMessage: 'Failed to load notification preferences',
    );
  }

  @override
  Future<NotificationPreferenceResponse> updatePreferences(
    UpdateNotificationPreferenceRequest request,
  ) async {
    final response = await dio.patch<Map<String, dynamic>>(
      ApiRoutes.notificationPreferences,
      data: request.toJson(),
    );

    return _unwrap(
      response.data,
      emptyMessage: 'Empty update notification preferences response',
      failureMessage: 'Failed to update notification preferences',
    );
  }

  NotificationPreferenceResponse _unwrap(
    Map<String, dynamic>? body, {
    required String emptyMessage,
    required String failureMessage,
  }) {
    if (body == null) {
      throw StateError(emptyMessage);
    }

    final apiResponse = ApiResponse<NotificationPreferenceResponse>.fromJson(
      body,
      (json) =>
          NotificationPreferenceResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? failureMessage);
    }

    return apiResponse.data!;
  }
}
