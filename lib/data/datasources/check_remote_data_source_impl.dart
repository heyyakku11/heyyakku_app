import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/check_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/models/checks/fun_card_type.dart';
import 'package:yakku/data/models/saved/saved_card.dart';
import 'package:yakku/data/models/checks/make_check_request.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';

class CheckRemoteDataSourceImpl implements CheckRemoteDataSource {
  CheckRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<List<CheckResponse>> getChecks() async {
    final response = await dio.get<Map<String, dynamic>>(ApiRoutes.checks);
    return _unwrapList(
      response.data,
      emptyMessage: 'Empty checks response',
      failureMessage: 'Failed to load checks',
      itemFromJson: CheckResponse.fromJson,
    );
  }

  @override
  Future<List<FunCardType>> getFunCardTypes() async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.funCardTypes,
    );
    return _unwrapList(
      response.data,
      emptyMessage: 'Empty card types response',
      failureMessage: 'Failed to load cards',
      itemFromJson: FunCardType.fromJson,
    );
  }

  @override
  Future<List<CheckResponse>> getFunCardsOfType(String typeId) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.funCardsOfType(typeId),
    );
    return _unwrapList(
      response.data,
      emptyMessage: 'Empty cards response',
      failureMessage: 'Failed to load cards',
      itemFromJson: CheckResponse.fromJson,
    );
  }

  @override
  Future<void> saveFunCard(String id) async {
    await dio.put<Map<String, dynamic>>(
      ApiRoutes.savedCard(SavedCardType.funCard.apiValue, id),
    );
  }

  @override
  Future<void> unsaveFunCard(String id) async {
    await dio.delete<Map<String, dynamic>>(
      ApiRoutes.savedCard(SavedCardType.funCard.apiValue, id),
    );
  }

  @override
  Future<UserCheckResponse> makeCheck(MakeCheckRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      request.fun ? ApiRoutes.makeFunCard : ApiRoutes.makeCheck,
      data: request.toJson(),
    );
    final body = response.data;
    if (body == null) throw StateError('Empty make check response');

    final apiResponse = ApiResponse<UserCheckResponse>.fromJson(
      body,
      (json) => UserCheckResponse.fromJson(json as Map<String, dynamic>),
    );
    final data = apiResponse.data;
    if (!apiResponse.success || data == null) {
      throw StateError(apiResponse.message ?? 'Could not make this check');
    }
    return data;
  }

  @override
  Future<List<UserCheckResponse>> getMyChecks() async {
    final response = await dio.get<Map<String, dynamic>>(ApiRoutes.myChecks);
    return _unwrapList(
      response.data,
      emptyMessage: 'Empty my checks response',
      failureMessage: 'Failed to load your checks',
      itemFromJson: UserCheckResponse.fromJson,
    );
  }

  @override
  Future<void> reshareMyCheck(String id) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.reshareMyCheck(id),
    );
    _expectSuccess(response.data, 'Could not reshare this card');
  }

  @override
  Future<void> closeMyCheck(String id) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.closeMyCheck(id),
    );
    _expectSuccess(response.data, 'Could not close this check');
  }

  @override
  Future<List<PollReason>> getCheckOptionReasons(
    String id,
    String optionId,
  ) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.checkOptionReasons(id, optionId),
    );
    return parseReasons(response.data);
  }

  @override
  Future<List<PollCustomAnswer>> getCheckCustomAnswers(String id) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.checkCustomAnswers(id),
    );
    return parseCustomAnswers(response.data);
  }

  @override
  Future<ReasonReportResult> reportCheckReason(
    String id,
    String reasonId,
  ) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.reportCheckReason(id, reasonId),
    );
    return parseReportResult(response.data);
  }

  @override
  Future<void> deleteMyCheck(String id) async {
    final response = await dio.delete<Map<String, dynamic>>(
      ApiRoutes.deleteMyCheck(id),
    );
    _expectSuccess(response.data, 'Could not delete this check');
  }
}

void _expectSuccess(Map<String, dynamic>? body, String failureMessage) {
  if (body == null) throw StateError(failureMessage);
  final apiResponse = ApiResponse<Object?>.fromJson(body, null);
  if (!apiResponse.success) {
    throw StateError(apiResponse.message ?? failureMessage);
  }
}

List<T> _unwrapList<T>(
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

  final data = apiResponse.data;
  if (!apiResponse.success || data == null) {
    throw StateError(apiResponse.message ?? failureMessage);
  }
  return data;
}
