import 'package:yakku/data/models/poll/user_poll_response.dart';

abstract interface class ActivityPollRemoteDataSource {
  Future<UserPollsPage> getAskedPolls({String? cursor});

  Future<UserPollsPage> getAnsweredPolls({String? cursor});
}
