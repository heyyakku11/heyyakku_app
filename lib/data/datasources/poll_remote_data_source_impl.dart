import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/poll_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/create_poll_request.dart';
import 'package:yakku/data/models/poll/poll_response.dart';

class PollRemoteDataSourceImpl implements PollRemoteDataSource {
  PollRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<PollResponse> createPoll(CreatePollRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.createPoll,
      data: request.toJson(),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty create poll response');
    }

    final apiResponse = ApiResponse<PollResponse>.fromJson(
      body,
      (json) => PollResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Create poll failed');
    }

    return apiResponse.data!;
  }

  @override
  Future<CastVoteResponse> castVote({
    required String pollId,
    required CastVoteRequest request,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.castVote(pollId),
      data: request.toJson(),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty cast vote response');
    }

    final apiResponse = ApiResponse<CastVoteResponse>.fromJson(
      body,
      (json) => CastVoteResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Cast vote failed');
    }

    return apiResponse.data!;
  }
}
