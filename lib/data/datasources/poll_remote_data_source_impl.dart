import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/poll_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/create_poll_request.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/shared_poll_response.dart';

class PollRemoteDataSourceImpl implements PollRemoteDataSource {
  PollRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<PollsPage> getPolls({String? cursor}) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.polls,
      queryParameters: _cursorQuery(cursor),
    );

    final apiResponse = _unwrapList(
      response.data,
      emptyMessage: 'Empty polls response',
      failureMessage: 'Failed to load polls',
      itemFromJson: PollResponse.fromJson,
    );

    return _toPollsPage(apiResponse);
  }

  @override
  Future<PollResponse> getPollById(String pollId) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.pollById(pollId),
    );

    return _unwrap(
      response.data,
      emptyMessage: 'Empty poll response',
      failureMessage: 'Failed to load poll',
      fromJson: PollResponse.fromJson,
    );
  }

  @override
  Future<SharedPollResponse> getSharedPoll(String shareToken) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.pollByShareToken(shareToken),
    );

    return _unwrap(
      response.data,
      emptyMessage: 'Empty shared poll response',
      failureMessage: 'Failed to load shared poll',
      fromJson: SharedPollResponse.fromJson,
    );
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

    return _unwrap(
      response.data,
      emptyMessage: 'Empty cast vote response',
      failureMessage: 'Cast vote failed',
      fromJson: CastVoteResponse.fromJson,
    );
  }

  PollsPage _toPollsPage(ApiResponse<List<PollResponse>> apiResponse) {
    final cursor = cursorFromMeta(apiResponse.meta);
    return PollsPage(
      items: apiResponse.data!,
      nextCursor: cursor.nextCursor,
      hasMore: cursor.hasMore,
    );
  }
}

Map<String, dynamic>? _cursorQuery(String? cursor) {
  if (cursor == null || cursor.isEmpty) return null;
  return <String, dynamic>{'cursor': cursor};
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

ApiResponse<List<T>> _unwrapList<T>(
  Map<String, dynamic>? body, {
  required String emptyMessage,
  required String failureMessage,
  required T Function(Map<String, dynamic> json) itemFromJson,
}) {
  if (body == null) {
    throw StateError(emptyMessage);
  }

  final apiResponse = ApiResponse<List<T>>.fromJson(body, (json) {
    if (json is! List) return <T>[];
    return json
        .whereType<Map>()
        .map((item) => itemFromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  });

  if (!apiResponse.success || apiResponse.data == null) {
    throw StateError(apiResponse.message ?? failureMessage);
  }

  return apiResponse;
}
