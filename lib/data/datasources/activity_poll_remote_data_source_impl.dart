import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/activity_poll_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/poll/user_poll_response.dart';

class ActivityPollRemoteDataSourceImpl implements ActivityPollRemoteDataSource {
  ActivityPollRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<UserPollsPage> getAskedPolls({String? cursor}) {
    return _fetchPolls(ApiRoutes.askedPolls, cursor: cursor);
  }

  @override
  Future<UserPollsPage> getAnsweredPolls({String? cursor}) {
    return _fetchPolls(ApiRoutes.answeredPolls, cursor: cursor);
  }

  Future<UserPollsPage> _fetchPolls(String path, {String? cursor}) async {
    final response = await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: cursor == null || cursor.isEmpty
          ? null
          : <String, dynamic>{'cursor': cursor},
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty activity polls response');
    }

    final apiResponse = ApiResponse<List<UserPollResponse>>.fromJson(
      body,
      (json) {
        if (json is! List) return const <UserPollResponse>[];
        return json
            .whereType<Map>()
            .map(
              (item) =>
                  UserPollResponse.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
      },
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to load activity polls');
    }

    final meta = apiResponse.meta;
    String? nextCursor;
    var hasMore = false;
    if (meta is Map) {
      final metaMap = Map<String, dynamic>.from(meta);
      nextCursor = metaMap['nextCursor'] as String?;
      hasMore = metaMap['hasMore'] as bool? ?? false;
    }

    return UserPollsPage(
      items: apiResponse.data!,
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }
}
