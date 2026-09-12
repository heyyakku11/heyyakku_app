import 'package:yakku/data/datasources/activity_poll_datasource.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';

class DummyActivityPollRepository implements ActivityPollRepository {
  const DummyActivityPollRepository({
    this.dataSource = const ActivityPollDataSource(),
  });

  final ActivityPollDataSource dataSource;

  @override
  Future<List<PollModel>> getCreatedPolls() async {
    return dataSource.fetchCreatedPolls();
  }

  @override
  Future<List<PollModel>> getAnsweredPolls() async {
    return dataSource.fetchAnsweredPolls();
  }
}
