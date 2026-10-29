import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/notification/app_notification.dart';

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this.dio);

  final Dio dio;

  final ValueNotifier<int> _readChanges = ValueNotifier<int>(0);

  @override
  Listenable get readChanges => _readChanges;

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
  Future<int> getUnreadCount() async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.notificationsUnreadCount,
    );
    final body = response.data;
    if (body == null) throw StateError('Empty unread count response');
    final apiResponse = ApiResponse<int>.fromJson(body, (json) {
      final count = json is Map ? json['count'] : null;
      return count is num ? count.toInt() : 0;
    });
    if (!apiResponse.success) {
      throw StateError(apiResponse.message ?? 'Failed to load unread count');
    }
    return apiResponse.data ?? 0;
  }

  @override
  Future<void> markAllRead() async {
    final response = await dio.patch<Map<String, dynamic>>(
      ApiRoutes.notificationsReadAll,
    );
    final body = response.data;
    if (body == null) throw StateError('Empty mark-all-read response');
    final apiResponse = ApiResponse<Object?>.fromJson(body, null);
    if (!apiResponse.success) {
      throw StateError(apiResponse.message ?? 'Failed to mark all as read');
    }
  }

  @override
  Future<void> markContentRead(String contentType, String contentId) async {
    final response = await dio.patch<Map<String, dynamic>>(
      ApiRoutes.notificationsContentRead(contentType, contentId),
    );
    final body = response.data;
    if (body == null) throw StateError('Empty mark-content-read response');
    final apiResponse = ApiResponse<Object?>.fromJson(body, null);
    if (!apiResponse.success) {
      throw StateError(apiResponse.message ?? 'Failed to mark as read');
    }
    _readChanges.value++;
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
