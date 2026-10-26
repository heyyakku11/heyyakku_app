import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/notification/app_notification.dart';

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<NotificationsPage> getNotifications({String? cursor}) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.notifications,
      queryParameters: cursor == null || cursor.isEmpty
          ? null
          : <String, dynamic>{'cursor': cursor},
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty notifications response');
    }

    final apiResponse = ApiResponse<List<AppNotification>>.fromJson(body, (
      json,
    ) {
      if (json is! List) return const <AppNotification>[];
      return json
          .whereType<Map>()
          .map(
            (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    });

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to load notifications');
    }

    final cursorInfo = cursorFromMeta(apiResponse.meta);
    return NotificationsPage(
      items: apiResponse.data!,
      nextCursor: cursorInfo.nextCursor,
      hasMore: cursorInfo.hasMore,
    );
  }

  @override
  Future<AppNotification> markRead(String id) async {
    final response = await dio.patch<Map<String, dynamic>>(
      ApiRoutes.notificationRead(id),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty mark-read response');
    }

    final apiResponse = ApiResponse<AppNotification>.fromJson(
      body,
      (json) => AppNotification.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to mark as read');
    }

    return apiResponse.data!;
  }
}
