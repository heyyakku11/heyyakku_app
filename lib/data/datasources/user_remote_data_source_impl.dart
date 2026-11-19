import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/community/community_queued_question.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/saved_poll_state_response.dart';
import 'package:yakku/data/models/saved/saved_card.dart';
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
  Future<List<YakkuPlan>> listPlans() async {
    final response = await dio.get<Map<String, dynamic>>(ApiRoutes.plans);
    final body = response.data;
    if (body == null) throw StateError('Empty plans response');

    final apiResponse = ApiResponse<List<YakkuPlan>>.fromJson(body, (json) {
      final list = json is List ? json : const [];
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) YakkuPlan.fromJson(item),
      ];
    });
    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to load plans');
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
  Future<bool> setPersonalityCommunitySharing(bool share) async {
    final response = await dio.put<Map<String, dynamic>>(
      ApiRoutes.personalityCommunitySharing,
      data: <String, dynamic>{'shareToCommunity': share},
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Empty community sharing response');
    }

    final apiResponse = ApiResponse<bool>.fromJson(
      body,
      (json) => json is Map<String, dynamic>
          ? json['shareToCommunity'] as bool? ?? share
          : share,
    );
    if (!apiResponse.success) {
      throw StateError(
        apiResponse.message ?? 'Could not update community sharing',
      );
    }
    return apiResponse.data ?? share;
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
  Future<SharedPersonalityCard> getSharedPersonalityCard(
    String shareCode,
  ) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.sharedPersonalityCard(shareCode),
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Empty shared personality card response');
    }

    final apiResponse = ApiResponse<SharedPersonalityCard>.fromJson(
      body,
      (json) => SharedPersonalityCard.fromJson(json as Map<String, dynamic>),
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
  Future<PersonalityVoteResult> votePersonalityCard(
    String shareCode,
    List<String> traitIds,
  ) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.personalityVote(shareCode),
      data: <String, dynamic>{'traitIds': traitIds},
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Empty personality vote response');
    }

    final apiResponse = ApiResponse<PersonalityVoteResult>.fromJson(
      body,
      (json) => PersonalityVoteResult.fromJson(json as Map<String, dynamic>),
    );
    final result = apiResponse.data;
    if (!apiResponse.success || result == null) {
      throw StateError(apiResponse.message ?? 'Failed to submit your vote');
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
  Future<void> joinCommunityWaitlist() async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.communityNotifyMe,
    );
    final body = response.data;
    if (body == null) throw StateError('Empty notify me response');
    final apiResponse = ApiResponse<Object?>.fromJson(body, null);
    if (!apiResponse.success) {
      throw StateError(apiResponse.message ?? 'Could not save your request');
    }
  }

  @override
  Future<List<CommunityQueuedQuestion>> listCommunityQueuedQuestions() async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.communityQueuedQuestions,
    );
    final body = response.data;
    if (body == null) throw StateError('Empty queued questions response');

    final apiResponse = ApiResponse<List<CommunityQueuedQuestion>>.fromJson(
      body,
      (json) {
        final list = json is List ? json : const [];
        return [
          for (final item in list)
            if (item is Map<String, dynamic>)
              CommunityQueuedQuestion.fromJson(item),
        ];
      },
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(
        apiResponse.message ?? 'Failed to load queued questions',
      );
    }
    return apiResponse.data!;
  }

  @override
  Future<CommunityQueuedQuestion> createCommunityQueuedQuestion({
    required String question,
    required List<String> tags,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.communityQueuedQuestions,
      data: {'question': question, 'tags': tags},
    );
    return _parseQueuedQuestion(
      response.data,
      emptyMessage: 'Empty create queued question response',
      failMessage: 'Could not queue your question',
    );
  }

  @override
  Future<CommunityQueuedQuestion> updateCommunityQueuedQuestion({
    required String id,
    required String question,
    required List<String> tags,
  }) async {
    final response = await dio.put<Map<String, dynamic>>(
      ApiRoutes.communityQueuedQuestion(id),
      data: {'question': question, 'tags': tags},
    );
    return _parseQueuedQuestion(
      response.data,
      emptyMessage: 'Empty update queued question response',
      failMessage: 'Could not update your question',
    );
  }

  @override
  Future<void> deleteCommunityQueuedQuestion(String id) async {
    final response = await dio.delete<Map<String, dynamic>>(
      ApiRoutes.communityQueuedQuestion(id),
    );
    final body = response.data;
    if (body == null) throw StateError('Empty delete queued question response');
    final apiResponse = ApiResponse<Object?>.fromJson(body, null);
    if (!apiResponse.success) {
      throw StateError(
        apiResponse.message ?? 'Could not remove your question',
      );
    }
  }

  CommunityQueuedQuestion _parseQueuedQuestion(
    Map<String, dynamic>? body, {
    required String emptyMessage,
    required String failMessage,
  }) {
    if (body == null) throw StateError(emptyMessage);
    final apiResponse = ApiResponse<CommunityQueuedQuestion>.fromJson(
      body,
      (json) => CommunityQueuedQuestion.fromJson(json as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? failMessage);
    }
    return apiResponse.data!;
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
  Future<SavedCardsPage> getSavedCards({String? cursor}) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.savedCards,
      queryParameters: cursor == null || cursor.isEmpty
          ? null
          : <String, dynamic>{'cursor': cursor},
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty saved cards response');
    }

    final apiResponse = ApiResponse<List<SavedCardItem>>.fromJson(body, (json) {
      if (json is! List) return <SavedCardItem>[];
      return [
        for (final item in json.whereType<Map>())
          if (SavedCardItem.tryParse(Map<String, dynamic>.from(item))
              case final card?)
            card,
      ];
    });

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to load saved cards');
    }

    final cursorMeta = cursorFromMeta(apiResponse.meta);
    return SavedCardsPage(
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
    final path = ApiRoutes.savedCard(SavedCardType.poll.apiValue, pollId);
    final response = delete
        ? await dio.delete<Map<String, dynamic>>(path)
        : await dio.put<Map<String, dynamic>>(path);

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
  Future<PollResponse> resharePoll(String pollId) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.resharePoll(pollId),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty reshare poll response');
    }

    final apiResponse = ApiResponse<PollResponse>.fromJson(
      body,
      (json) => PollResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to reshare poll');
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
  Future<PollReasonList> getPollOptionReasons(
    String pollId,
    String optionId,
  ) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.pollOptionReasons(pollId, optionId),
    );
    return parseReasons(response.data);
  }

  @override
  Future<PollCustomAnswerList> getPollCustomAnswers(String pollId) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.pollCustomAnswers(pollId),
    );
    return parseCustomAnswers(response.data);
  }

  @override
  Future<ReasonReportResult> reportPollReason(
    String pollId,
    String reasonId, {
    required String reason,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.reportPollReason(pollId, reasonId),
      data: {'reason': reason.trim()},
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
