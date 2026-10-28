import 'package:yakku/data/models/poll/poll_reason.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/saved_poll_state_response.dart';
import 'package:yakku/data/models/user/user_poll_detail_response.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';

abstract interface class UserRemoteDataSource {
  Future<UserProfileResponse> getMe();

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
