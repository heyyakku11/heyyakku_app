import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/saved_poll_state_response.dart';
import 'package:yakku/data/models/user/user_poll_detail_response.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<UserProfileResponse> getMe() async {
    final response = await dio.get<Map<String, dynamic>>(ApiRoutes.getMe);

    final body = response.data;
    if (body == null) {
      throw StateError('Empty get me response');
    }

    final apiResponse = ApiResponse<UserProfileResponse>.fromJson(
      body,
      (json) => UserProfileResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to load user profile');
    }

    return apiResponse.data!;
  }

  @override
  Future<PollsPage> getSavedPolls({String? cursor}) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.savedPolls,
      queryParameters: cursor == null || cursor.isEmpty
          ? null
          : <String, dynamic>{'cursor': cursor},
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty saved polls response');
    }

    final apiResponse = ApiResponse<List<PollResponse>>.fromJson(body, (json) {
      if (json is! List) return <PollResponse>[];
      return json
          .whereType<Map>()
          .map((item) => PollResponse.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    });

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to load saved polls');
    }

    final cursorMeta = cursorFromMeta(apiResponse.meta);
    return PollsPage(
      items: apiResponse.data!,
      nextCursor: cursorMeta.nextCursor,
      hasMore: cursorMeta.hasMore,
    );
  }

  @override
  Future<SavedPollStateResponse> savePoll(String pollId) {
    return _setSaved(pollId, delete: false);
  }

  @override
  Future<SavedPollStateResponse> unsavePoll(String pollId) {
    return _setSaved(pollId, delete: true);
  }

  Future<SavedPollStateResponse> _setSaved(
    String pollId, {
    required bool delete,
  }) async {
    final path = ApiRoutes.savePoll(pollId);
    final response = delete
        ? await dio.delete<Map<String, dynamic>>(path)
        : await dio.post<Map<String, dynamic>>(path);

    final body = response.data;
    if (body == null) {
      throw StateError(
        delete ? 'Empty unsave poll response' : 'Empty save poll response',
      );
    }

    final apiResponse = ApiResponse<SavedPollStateResponse>.fromJson(
      body,
      (json) => SavedPollStateResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(
        apiResponse.message ??
            (delete ? 'Failed to unsave poll' : 'Failed to save poll'),
      );
    }

    return apiResponse.data!;
  }

  @override
  Future<UserPollDetailResponse> getOwnedPollDetails(String pollId) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.viewPoll(pollId),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty view poll response');
    }

    final apiResponse = ApiResponse<UserPollDetailResponse>.fromJson(
      body,
      (json) => UserPollDetailResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to load poll details');
    }

    return apiResponse.data!;
  }

  @override
  Future<PollResponse> closePoll(String pollId) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.closePoll(pollId),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty close poll response');
    }

    final apiResponse = ApiResponse<PollResponse>.fromJson(
      body,
      (json) => PollResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to close poll');
    }

    return apiResponse.data!;
  }

  @override
  Future<void> deletePoll(String pollId) async {
    final response = await dio.delete<Map<String, dynamic>>(
      ApiRoutes.deletePoll(pollId),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty delete poll response');
    }

    final apiResponse = ApiResponse<Object?>.fromJson(body, null);

    if (!apiResponse.success) {
      throw StateError(apiResponse.message ?? 'Failed to delete poll');
    }
  }
}
