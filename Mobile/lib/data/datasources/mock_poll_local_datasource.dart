import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/domain/entities/anonymous_user.dart';
import 'package:yakku/domain/entities/poll.dart';
import 'package:yakku/domain/entities/poll_option.dart';
import 'package:yakku/domain/enums/poll_status.dart';

class MockPollLocalDataSource {
  MockPollLocalDataSource() {
    _seed();
  }

  static const currentUserId = 'user-me';

  late AnonymousUser currentUser;
  final List<Poll> polls = [];

  void _seed() {
    final now = DateTime.now();
    currentUser = const AnonymousUser(
      id: currentUserId,
      displayName: 'Anonymous User',
      avatarSeed: 11,
      questionsCount: 24,
      votesReceived: 1200,
      answersCount: 86,
    );

    polls.addAll([
      _poll(
        id: 'poll-skill',
        creatorId: 'user-a',
        question: 'What skill should everyone learn?',
        createdAt: now.subtract(const Duration(hours: 2)),
        selectedOptionIds: const {},
        options: const [
          ('opt-skill-1', 'Cooking', 0, 42),
          ('opt-skill-2', 'Communication', 1, 88),
          ('opt-skill-3', 'Investing', 2, 51),
          ('opt-skill-4', 'First Aid', 3, 37),
          ('opt-skill-else', 'Something else', 4, 12),
        ],
      ),
      _poll(
        id: 'poll-tech',
        creatorId: 'user-b',
        question: 'Which technology would you learn next?',
        createdAt: now.subtract(const Duration(hours: 5)),
        selectedOptionIds: const {},
        options: const [
          ('opt-tech-1', 'Flutter', 0, 96),
          ('opt-tech-2', 'React', 1, 71),
          ('opt-tech-3', '.NET', 2, 44),
          ('opt-tech-4', 'Node.js', 3, 58),
          ('opt-tech-else', 'Something else', 4, 18),
        ],
      ),
      _poll(
        id: 'poll-learn',
        creatorId: currentUserId,
        question: 'What is the best way to learn programming?',
        createdAt: now.subtract(const Duration(days: 1)),
        selectedOptionIds: const {'opt-learn-1'},
        options: const [
          ('opt-learn-1', 'Flutter', 0, 45),
          ('opt-learn-2', 'YouTube', 1, 30),
          ('opt-learn-3', 'Books', 2, 15),
          ('opt-learn-4', 'Courses', 3, 10),
          ('opt-learn-else', 'Something else', 4, 8),
        ],
      ),
      _poll(
        id: 'poll-language',
        creatorId: currentUserId,
        question: 'Best programming language?',
        createdAt: now.subtract(const Duration(days: 2)),
        selectedOptionIds: const {'opt-lang-2'},
        options: const [
          ('opt-lang-1', 'Dart', 0, 34),
          ('opt-lang-2', 'TypeScript', 1, 41),
          ('opt-lang-3', 'Python', 2, 62),
          ('opt-lang-4', 'Go', 3, 19),
          ('opt-lang-else', 'Something else', 4, 7),
        ],
      ),
    ]);
  }

  Poll _poll({
    required String id,
    required String creatorId,
    required String question,
    required DateTime createdAt,
    required Set<String> selectedOptionIds,
    required List<(String, String, int, int)> options,
  }) {
    return Poll(
      id: id,
      creatorId: creatorId,
      question: question,
      createdAt: createdAt,
      selectedOptionIds: selectedOptionIds,
      status: PollStatus.active,
      expiresAt: createdAt.add(const Duration(days: 7)),
      options: [
        for (final option in options)
          PollOption(
            id: option.$1,
            pollId: id,
            text: option.$2,
            position: option.$3,
            voteCount: option.$4,
            isSomethingElse: option.$2 == AppLimits.somethingElseLabel,
          ),
      ],
    );
  }
}
