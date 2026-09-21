import 'package:yakku/data/models/Poll.dart';

/// Activity poll lists (asked / answered).
///
/// Production: [ApiActivityPollRepository] via [AppScope.activityPolls].
abstract class ActivityPollRepository {
  Future<List<PollModel>> getCreatedPolls();

  Future<List<PollModel>> getAnsweredPolls();
}
