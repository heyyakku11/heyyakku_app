import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';
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
  Future<PersonalityCard> getMyPersonalityCard() async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.myPersonalityCard,
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Empty personality card response');
    }

    final apiResponse = ApiResponse<PersonalityCard>.fromJson(
      body,
      (json) => PersonalityCard.fromJson(json as Map<String, dynamic>),
    );
    final card = apiResponse.data;
    if (!apiResponse.success || card == null) {
      throw StateError(
        apiResponse.message ?? 'Failed to load personality card',
      );
    }
    return card;
  }

  @override
  Future<PersonalityResults> getPersonalityResults(String shareCode) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.personalityResults(shareCode),
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Empty personality results response');
    }

    final apiResponse = ApiResponse<PersonalityResults>.fromJson(
      body,
      (json) => PersonalityResults.fromJson(json as Map<String, dynamic>),
    );
    final results = apiResponse.data;
    if (!apiResponse.success || results == null) {
      throw StateError(apiResponse.message ?? 'Failed to load results');
    }
    return results;
  }

  @override
  Future<PersonalitySelfAssessment> submitSelfAssessment(
    List<String> traitIds,
  ) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.personalitySelfAssessment,
      data: <String, dynamic>{'traitIds': traitIds},
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Empty self-assessment response');
    }

    final apiResponse = ApiResponse<PersonalitySelfAssessment>.fromJson(
      body,
      (json) =>
          PersonalitySelfAssessment.fromJson(json as Map<String, dynamic>),
    );
    final result = apiResponse.data;
    if (!apiResponse.success || result == null) {
      throw StateError(apiResponse.message ?? 'Failed to save your guess');
    }
    return result;
  }

  @override
  Future<List<PersonalityTrait>> getPersonalityTraits() async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.personalityTraits,
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Empty personality traits response');
    }

    final apiResponse = ApiResponse<List<PersonalityTrait>>.fromJson(body, (
      json,
    ) {
      return [
        if (json is List)
          for (final item in json)
            if (item is Map<String, dynamic>) PersonalityTrait.fromJson(item),
      ];
    });
    if (!apiResponse.success) {
      throw StateError(apiResponse.message ?? 'Failed to load traits');
    }
    return apiResponse.data ?? const [];
  }

  @override
  Future<UserSettings> getSettings() async {
    final response = await dio.get<Map<String, dynamic>>(ApiRoutes.mySettings);
    return _readSettings(response.data);
  }

  @override
  Future<UserSettings> updateSettings({bool? allowAskBack}) async {
    final response = await dio.patch<Map<String, dynamic>>(
      ApiRoutes.mySettings,
      data: <String, dynamic>{
        if (allowAskBack != null) 'allowAskBack': allowAskBack,
      },
    );
    return _readSettings(response.data);
  }

  UserSettings _readSettings(Map<String, dynamic>? body) {
    if (body == null) {
      throw StateError('Empty settings response');
    }
    final apiResponse = ApiResponse<UserSettings>.fromJson(
      body,
      (json) => UserSettings.fromJson(json as Map<String, dynamic>),
    );
    final settings = apiResponse.data;
    if (!apiResponse.success || settings == null) {
      throw StateError(apiResponse.message ?? 'Failed to load settings');
    }
    return settings;
  }

  @override
  Future<String> regenerateAnonymousName() async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.regenerateAnonymousName,
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty regenerate anonymous name response');
    }

    final apiResponse = ApiResponse<String>.fromJson(body, (json) {
      final data = json is Map<String, dynamic>
          ? json
          : const <String, dynamic>{};
      return data['anonymousName'] as String? ?? '';
    });

    final name = apiResponse.data;
    if (!apiResponse.success || name == null || name.isEmpty) {
      throw StateError(
        apiResponse.message ?? 'Failed to update anonymous name',
      );
    }

    return name;
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
      ApiRoutes.pollById(pollId),
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
  Future<List<PollReason>> getPollOptionReasons(
    String pollId,
    String optionId,
  ) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.pollOptionReasons(pollId, optionId),
    );
    return parseReasons(response.data);
  }

  @override
  Future<List<PollCustomAnswer>> getPollCustomAnswers(String pollId) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.pollCustomAnswers(pollId),
    );
    return parseCustomAnswers(response.data);
  }

  @override
  Future<ReasonReportResult> reportPollReason(
    String pollId,
    String reasonId,
  ) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.reportPollReason(pollId, reasonId),
    );
    return parseReportResult(response.data);
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
