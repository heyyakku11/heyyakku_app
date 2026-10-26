import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/saved_poll_state_response.dart';
import 'package:yakku/data/models/user/user_poll_detail_response.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';

abstract interface class UserRemoteDataSource {
  Future<UserProfileResponse> getMe();

  /// `PATCH /api/v1/users/push`: turns push notifications on or off for the
  /// signed-in account and returns the updated profile.
  Future<UserProfileResponse> setPushAllowed(bool isPushAllowed);

  Future<PollsPage> getSavedPolls({String? cursor});

  Future<SavedPollStateResponse> savePoll(String pollId);

  Future<SavedPollStateResponse> unsavePoll(String pollId);

  Future<UserPollDetailResponse> getOwnedPollDetails(String pollId);

  Future<PollResponse> closePoll(String pollId);

  Future<void> deletePoll(String pollId);
}
