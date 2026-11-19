import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/models/community/community_queued_question.dart';

void main() {
  group('CommunityQueuedQuestion.fromJson', () {
    test('parses tags and personality traits', () {
      final question = CommunityQueuedQuestion.fromJson({
        'id': 'q1',
        'question': 'Should I quit?',
        'tags': ['career', 'money'],
        'createdAt': '2026-11-19T00:00:00Z',
        'updatedAt': '2026-11-19T01:00:00Z',
        'personalityTraits': [
          {'id': 't1', 'name': 'Loyal'},
          {'id': 't2', 'name': 'Funny'},
        ],
      });

      expect(question.id, 'q1');
      expect(question.question, 'Should I quit?');
      expect(question.tags, ['career', 'money']);
      expect(question.personalityTraits.map((t) => t.name), ['Loyal', 'Funny']);
      expect(question.createdAt.isUtc, isTrue);
    });

    test('defaults missing personality traits to empty', () {
      final question = CommunityQueuedQuestion.fromJson({
        'id': 'q2',
        'question': 'Hello?',
        'tags': ['love'],
        'createdAt': '2026-11-19T00:00:00Z',
        'updatedAt': '2026-11-19T00:00:00Z',
      });

      expect(question.personalityTraits, isEmpty);
      expect(CommunityQueuedQuestionCategories.label('love'), 'Love');
    });
  });
}
