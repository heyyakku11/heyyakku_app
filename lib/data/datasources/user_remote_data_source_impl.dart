import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
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
