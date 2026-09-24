import 'package:yakku/data/models/Poll.dart';

/// Stand-in poll feed until the real API is wired up.
class PollListDataSource {
  const PollListDataSource();

  List<Map<String, dynamic>> getPolls() =>
      List<Map<String, dynamic>>.from(_polls);

  List<PollModel> fetchActivePolls() {
    return PollModel.listFromJson(
      getPolls(),
    ).where((poll) => poll.status.isActive).toList(growable: false);
  }

  static const List<Map<String, dynamic>> _polls = [
    {
      'id': 'poll_101',
      'question': 'Should I text them again?',
      'categoryId': null,
      'answerType': 1,
      'allowCustomOption': true,
      'status': 1,
      'totalVoteCount': 42,
      'options': [
        {
          'id': 'option_1001',
          'type': 1,
          'text': 'Text them',
          'imageUrl': null,
          'sortOrder': 1,
          'isCustom': false,
        },
        {
          'id': 'option_1002',
          'type': 1,
          'text': 'Leave it',
          'imageUrl': null,
          'sortOrder': 2,
          'isCustom': false,
        },
        {
          'id': 'option_1003',
          'type': 1,
          'text': 'Wait a day',
          'imageUrl': null,
          'sortOrder': 3,
          'isCustom': false,
        },
      ],
      'whys': [
        {
          'id': 'why_101_1',
          'authorName': 'Riya',
          'text': 'One clear text is better than guessing all night.',
          'likeCount': 12,
          'optionId': 'option_1001',
        },
        {
          'id': 'why_101_2',
          'authorName': 'Mehul',
          'text': 'If they wanted to reply, they already would have.',
          'likeCount': 9,
          'optionId': 'option_1002',
        },
        {
          'id': 'why_101_3',
          'authorName': 'Anika',
          'text': 'Waiting a day keeps it from sounding desperate.',
          'likeCount': 7,
          'optionId': 'option_1003',
        },
        {
          'id': 'why_101_4',
          'authorName': 'Kabir',
          'text': 'Say what you mean and then leave the ball with them.',
          'likeCount': 6,
          'optionId': 'option_1001',
        },
        {
          'id': 'why_101_5',
          'authorName': 'Sana',
          'text': 'Silence is an answer. Protect your peace.',
          'likeCount': 5,
          'optionId': 'option_1002',
        },
        {
          'id': 'why_101_6',
          'authorName': 'Dev',
          'text': 'A short check-in tomorrow will land better.',
          'likeCount': 4,
          'optionId': 'option_1003',
        },
        {
          'id': 'why_101_7',
          'authorName': 'Leah',
          'text': 'You will keep replaying it until you send something.',
          'likeCount': 3,
          'optionId': 'option_1001',
        },
        {
          'id': 'why_101_8',
          'authorName': 'Omar',
          'text': 'Give them space. Interest does not need a chase.',
          'likeCount': 2,
          'optionId': 'option_1002',
        },
      ],
    },
    {
      'id': 'poll_102',
      'question': 'Which activities do you enjoy on weekends?',
      'categoryId': 'category_lifestyle',
      'answerType': 2,
      'allowCustomOption': true,
      'status': 1,
      'totalVoteCount': 18,
      'options': [
        {
          'id': 'option_1004',
          'type': 1,
          'text': 'Watching movies',
          'imageUrl': null,
          'sortOrder': 1,
          'isCustom': false,
        },
        {
          'id': 'option_1005',
          'type': 1,
          'text': 'Going out with friends',
          'imageUrl': null,
          'sortOrder': 2,
          'isCustom': false,
        },
        {
          'id': 'option_1006',
          'type': 1,
          'text': 'Playing games',
          'imageUrl': null,
          'sortOrder': 3,
          'isCustom': false,
        },
      ],
      'whys': [
        {
          'id': 'why_102_1',
          'authorName': 'Nora',
          'text': 'A movie night is the reset I actually finish.',
          'likeCount': 4,
          'optionId': 'option_1004',
        },
        {
          'id': 'why_102_2',
          'authorName': 'Arjun',
          'text': 'Weekends feel wasted if I never leave the house.',
          'likeCount': 2,
          'optionId': 'option_1005',
        },
      ],
    },
    {
      'id': 'poll_103',
      'question': 'Which design do you like the most?',
      'categoryId': 'category_design',
      'answerType': 1,
      'allowCustomOption': true,
      'status': 1,
      'totalVoteCount': 25,
      'options': [
        {
          'id': 'option_1008',
          'type': 2,
          'text': null,
          'imageUrl':
              'https://images.pexels.com/photos/8531660/pexels-photo-8531660.jpeg',
          'sortOrder': 1,
          'isCustom': false,
        },
        {
          'id': 'option_1009',
          'type': 2,
          'text': null,
          'imageUrl':
              'https://images.pexels.com/photos/14693247/pexels-photo-14693247.jpeg',
          'sortOrder': 2,
          'isCustom': false,
        },
        {
          'id': 'option_1010',
          'type': 2,
          'text': null,
          'imageUrl':
              'https://images.pexels.com/photos/17125499/pexels-photo-17125499.jpeg',
          'sortOrder': 3,
          'isCustom': false,
        },
      ],
      'whys': <Map<String, dynamic>>[],
    },
    {
      'id': 'poll_104',
      'question': 'What should we have for dinner tonight?',
      'categoryId': 'category_food',
      'answerType': 1,
      'allowCustomOption': true,
      'status': 1,
      'totalVoteCount': 30,
      'options': [
        {
          'id': 'option_1011',
          'type': 1,
          'text': 'Pizza',
          'imageUrl': null,
          'sortOrder': 1,
          'isCustom': false,
        },
        {
          'id': 'option_1012',
          'type': 1,
          'text': 'Biryani',
          'imageUrl': null,
          'sortOrder': 2,
          'isCustom': false,
        },
        {
          'id': 'option_1013',
          'type': 1,
          'text': 'Burger',
          'imageUrl': null,
          'sortOrder': 3,
          'isCustom': false,
        },
        {
          'id': 'option_1014',
          'type': 1,
          'text': 'Something else',
          'imageUrl': null,
          'sortOrder': 4,
          'isCustom': true,
        },
      ],
      'whys': [
        {
          'id': 'why_104_1',
          'authorName': 'Priya',
          'text': 'Pizza shares easily and nobody has to cook.',
          'likeCount': 8,
          'optionId': 'option_1011',
        },
        {
          'id': 'why_104_2',
          'authorName': 'Hassan',
          'text': 'Biryani is the one everyone actually finishes.',
          'likeCount': 11,
          'optionId': 'option_1012',
        },
        {
          'id': 'why_104_3',
          'authorName': 'Maya',
          'text': 'Burgers are fast if we are eating late.',
          'likeCount': 3,
          'optionId': 'option_1013',
        },
        {
          'id': 'why_104_4',
          'authorName': 'Leo',
          'text': 'We had pizza twice this week already.',
          'likeCount': 5,
          'optionId': 'option_1014',
        },
        {
          'id': 'why_104_5',
          'authorName': 'Aisha',
          'text': 'A good biryani beats takeaway every time.',
          'likeCount': 6,
          'optionId': 'option_1012',
        },
        {
          'id': 'why_104_6',
          'authorName': 'Chris',
          'text': 'Keep it simple. One large pizza, done.',
          'likeCount': 4,
          'optionId': 'option_1011',
        },
      ],
    },
    {
      'id': 'poll_105',
      'question': 'Which features should we add to the app?',
      'categoryId': 'category_product',
      'answerType': 2,
      'allowCustomOption': true,
      'status': 1,
      'totalVoteCount': 18,
      'options': [
        {
          'id': 'option_1015',
          'type': 1,
          'text': 'Dark mode',
          'imageUrl': null,
          'sortOrder': 1,
          'isCustom': false,
        },
        {
          'id': 'option_1016',
          'type': 1,
          'text': 'Cloud sync',
          'imageUrl': null,
          'sortOrder': 2,
          'isCustom': false,
        },
        {
          'id': 'option_1017',
          'type': 1,
          'text': 'Reminders',
          'imageUrl': null,
          'sortOrder': 3,
          'isCustom': false,
        },
      ],
      'whys': [
        {
          'id': 'why_105_1',
          'authorName': 'Jonah',
          'text': 'I open this at night. Dark mode should come first.',
          'likeCount': 5,
          'optionId': 'option_1015',
        },
      ],
    },
  ];
}
