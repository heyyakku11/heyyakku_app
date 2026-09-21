import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/notification/notification_response.dart';

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<NotificationsPage> getMine({String? cursor}) async {
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

    final apiResponse = ApiResponse<List<NotificationResponse>>.fromJson(
      body,
      (json) {
        if (json is! List) return const <NotificationResponse>[];
        return json
            .whereType<Map>()
            .map(
              (item) => NotificationResponse.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false);
      },
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to load notifications');
    }

    final meta = apiResponse.meta;
    String? nextCursor;
    var hasMore = false;
    if (meta is Map) {
      final metaMap = Map<String, dynamic>.from(meta);
      nextCursor = metaMap['nextCursor'] as String?;
      hasMore = metaMap['hasMore'] as bool? ?? false;
    }

    return NotificationsPage(
      items: apiResponse.data!,
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }

  @override
  Future<NotificationResponse> markAsRead(String id) async {
    final response = await dio.patch<Map<String, dynamic>>(
      ApiRoutes.markNotificationRead(id),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty mark notification read response');
    }

    final apiResponse = ApiResponse<NotificationResponse>.fromJson(
      body,
      (json) => NotificationResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(
        apiResponse.message ?? 'Failed to mark notification as read',
      );
    }

    return apiResponse.data!;
  }
}
