import 'package:yakku/data/models/Poll.dart';

/// Activity poll lists. Swap the dummy implementation for an API later.
abstract class ActivityPollRepository {
  Future<List<PollModel>> getCreatedPolls();

  Future<List<PollModel>> getAnsweredPolls();
}
