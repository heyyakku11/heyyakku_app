import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/user/user_poll_detail_response.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';

abstract interface class UserRemoteDataSource {
  Future<UserProfileResponse> getMe();

  Future<UserPollDetailResponse> getOwnedPollDetails(String pollId);

  Future<PollResponse> closePoll(String pollId);

  Future<void> deletePoll(String pollId);
}
