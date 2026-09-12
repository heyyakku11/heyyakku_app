import 'package:yakku/domain/entities/anonymous_user.dart';
import 'package:yakku/domain/entities/poll.dart';

class MockPollLocalDataSource {
  MockPollLocalDataSource() {
    currentUser = const AnonymousUser(
      id: currentUserId,
      displayName: 'Anonymous User',
      avatarSeed: 11,
      questionsCount: 0,
      votesReceived: 0,
      answersCount: 0,
    );
  }

  static const currentUserId = 'user-me';

  late AnonymousUser currentUser;
  final List<Poll> polls = [];
}
