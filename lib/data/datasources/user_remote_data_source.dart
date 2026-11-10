import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/saved_poll_state_response.dart';
import 'package:yakku/data/models/user/user_poll_detail_response.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';

abstract interface class UserRemoteDataSource {
  Future<UserProfileResponse> getMe();

  /// `GET /api/v1/users/me/settings`: the account-level settings.
  Future<UserSettings> getSettings();

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
  Future<PersonalitySelfAssessment> submitSelfAssessment(
    List<String> traitIds,
  );

  /// `GET /api/v1/personality-cards/{shareCode}/results`: what friends said,
  /// once the card is completed.
  Future<PersonalityResults> getPersonalityResults(String shareCode);

  /// `GET /api/v1/personality/traits`: the predefined traits friends pick from.
  Future<List<PersonalityTrait>> getPersonalityTraits();

  Future<PollsPage> getSavedPolls({String? cursor});

  Future<SavedPollStateResponse> savePoll(String pollId);

  Future<SavedPollStateResponse> unsavePoll(String pollId);

  Future<UserPollDetailResponse> getOwnedPollDetails(String pollId);

  Future<PollResponse> closePoll(String pollId);

  Future<void> deletePoll(String pollId);

  /// The reasons voters gave for one option of a poll the caller owns.
  Future<List<PollReason>> getPollOptionReasons(String pollId, String optionId);

  /// The custom answers voters wrote in on a poll the caller owns, with reasons.
  Future<List<PollCustomAnswer>> getPollCustomAnswers(String pollId);

  /// Reports a reason as abuse: it is removed and logged.
  Future<ReasonReportResult> reportPollReason(String pollId, String reasonId);
}
