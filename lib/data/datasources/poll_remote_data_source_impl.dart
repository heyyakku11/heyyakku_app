import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/poll_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/create_poll_request.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/shared_content_response.dart';
import 'package:yakku/data/models/user/user_poll_detail_response.dart';

class PollRemoteDataSourceImpl implements PollRemoteDataSource {
  PollRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<PollResponse> getPollById(String pollId) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.pollById(pollId),
    );

    final detail = _unwrap(
      response.data,
      emptyMessage: 'Empty poll response',
      failureMessage: 'Failed to load poll',
      fromJson: UserPollDetailResponse.fromJson,
    );
    return detail.toPollResponse();
  }

  @override
  Future<PollResponse> getPollByShareCode(String shareCode) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.sharedContent(shareCode),
    );

    final content = _unwrap(
      response.data,
      emptyMessage: 'Empty shared poll response',
      failureMessage: 'Failed to load shared poll',
      fromJson: SharedContentResponse.fromJson,
    );
    return content.toPollResponse();
  }

  @override
  Future<PollResponse> createPoll(CreatePollRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.createPoll,
      data: request.toJson(),
    );

    return _unwrap(
      response.data,
      emptyMessage: 'Empty create poll response',
      failureMessage: 'Create poll failed',
      fromJson: PollResponse.fromJson,
    );
  }

  @override
  Future<CastVoteResponse> castVote(CastVoteRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.castVote,
      data: request.toJson(),
    );

    final content = _unwrap(
      response.data,
      emptyMessage: 'Empty cast vote response',
      failureMessage: 'Cast vote failed',
      fromJson: SharedContentResponse.fromJson,
    );
    return CastVoteResponse.fromShared(content);
  }
}

T _unwrap<T>(
  Map<String, dynamic>? body, {
  required String emptyMessage,
  required String failureMessage,
  required T Function(Map<String, dynamic> json) fromJson,
}) {
  if (body == null) {
    throw StateError(emptyMessage);
  }

  final apiResponse = ApiResponse<T>.fromJson(
    body,
    (json) => fromJson(json as Map<String, dynamic>),
  );

  final data = apiResponse.data;
  if (!apiResponse.success || data == null) {
    throw StateError(apiResponse.message ?? failureMessage);
  }

  return data as T;
}
