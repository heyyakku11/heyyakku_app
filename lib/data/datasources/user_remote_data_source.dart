import 'package:yakku/data/models/community/community_queued_question.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/saved_poll_state_response.dart';
import 'package:yakku/data/models/saved/saved_card.dart';
import 'package:yakku/data/models/user/user_poll_detail_response.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';

abstract interface class UserRemoteDataSource {
  Future<UserProfileResponse> getMe();

  /// `GET /api/v1/plans`: subscription catalog in hierarchy order.
  Future<List<YakkuPlan>> listPlans();

  /// `GET /api/v1/users/me/settings`: the account-level settings.
  Future<UserSettings> getSettings();

  /// Adds the signed-in user to the queue notified when the community goes live. Safe to repeat.
  Future<void> joinCommunityWaitlist();

  /// `GET /api/v1/community/queued-questions`: the caller's queued questions.
  Future<List<CommunityQueuedQuestion>> listCommunityQueuedQuestions();

  /// `POST /api/v1/community/queued-questions`: queues a question (max 3).
  Future<CommunityQueuedQuestion> createCommunityQueuedQuestion({
    required String question,
    required List<String> tags,
  });

  /// `PUT /api/v1/community/queued-questions/{id}`: updates an owned queued question.
  Future<CommunityQueuedQuestion> updateCommunityQueuedQuestion({
    required String id,
    required String question,
    required List<String> tags,
  });

  /// `DELETE /api/v1/community/queued-questions/{id}`: removes an owned queued question.
  Future<void> deleteCommunityQueuedQuestion(String id);

  /// `PATCH /api/v1/users/me/settings`: changes the settings that are given
  /// and returns all of them. Independent of the device's push setting.
  Future<UserSettings> updateSettings({bool? allowAskBack});

  /// `POST /api/v1/users/me/anonymous-name`: the server picks a new unique
  /// name, saves it to the profile and returns it.
  Future<String> regenerateAnonymousName();

  /// `GET /api/v1/personality-cards/me`: the signed-in user's own card.
  Future<PersonalityCard> getMyPersonalityCard();

  /// `POST /api/v1/personality-cards/me/self-assessment`: claims exactly 3
  /// distinct traits for the user's own card. Allowed once; the card then
  /// starts collecting friends' votes.
  Future<PersonalitySelfAssessment> submitSelfAssessment(List<String> traitIds);

  /// `GET /api/v1/personality-cards/{shareCode}/results`: what friends said,
  /// once the card is completed.
  Future<PersonalityResults> getPersonalityResults(String shareCode);

  /// `PUT /api/v1/personality-cards/me/community-sharing`: turns sharing the
  /// completed card's final result in the community on or off. Returns the
  /// saved choice.
  Future<bool> setPersonalityCommunitySharing(bool share);

  /// `GET /api/v1/personality-cards/{shareCode}`: a friend's card as a voter
  /// sees it (own card, already voted, can vote).
  Future<SharedPersonalityCard> getSharedPersonalityCard(String shareCode);

  /// `POST /api/v1/personality-cards/{shareCode}/votes`: picks exactly 3
  /// distinct traits that describe the card's owner. One vote per voter, never
  /// on your own card.
  Future<PersonalityVoteResult> votePersonalityCard(
    String shareCode,
    List<String> traitIds,
  );

  /// `GET /api/v1/personality/traits`: the predefined traits friends pick from.
  Future<List<PersonalityTrait>> getPersonalityTraits();

  /// One page of the saved cards, polls and fun cards together, newest saved first.
  Future<SavedCardsPage> getSavedCards({String? cursor});

  Future<SavedPollStateResponse> savePoll(String pollId);

  Future<SavedPollStateResponse> unsavePoll(String pollId);

  Future<UserPollDetailResponse> getOwnedPollDetails(String pollId);

  Future<PollResponse> closePoll(String pollId);

  /// Opens one of the caller's closed polls again for another 24 hours (same share link).
  Future<PollResponse> resharePoll(String pollId);

  Future<void> deletePoll(String pollId);

  /// The reasons voters gave for one option of a poll the caller owns.
  Future<PollReasonList> getPollOptionReasons(String pollId, String optionId);

  /// The custom answers voters wrote in on a poll the caller owns, with reasons.
  Future<PollCustomAnswerList> getPollCustomAnswers(String pollId);

  /// Reports a reason as abuse. It stays visible, flagged, until an admin decides.
  Future<ReasonReportResult> reportPollReason(
    String pollId,
    String reasonId, {
    required String reason,
  });
}
