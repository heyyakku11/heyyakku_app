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
    },
    {
      'id': 'poll_102',
      'question': 'Which activities do you enjoy on weekends?',
      'categoryId': 'category_lifestyle',
      'answerType': 2,
      'allowCustomOption': true,
      'status': 1,
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
    },
    {
      'id': 'poll_103',
      'question': 'Which design do you like the most?',
      'categoryId': 'category_design',
      'answerType': 1,
      'allowCustomOption': true,
      'status': 1,
      'options': [
        {
          'id': 'option_1008',
          'type': 2,
          'text': null,
          'imageUrl': 'https://example.com/images/design_01.png',
          'sortOrder': 1,
          'isCustom': false,
        },
        {
          'id': 'option_1009',
          'type': 2,
          'text': null,
          'imageUrl': 'https://example.com/images/design_02.png',
          'sortOrder': 2,
          'isCustom': false,
        },
        {
          'id': 'option_1010',
          'type': 2,
          'text': null,
          'imageUrl': 'https://example.com/images/design_03.png',
          'sortOrder': 3,
          'isCustom': false,
        },
      ],
    },
    {
      'id': 'poll_104',
      'question': 'What should we have for dinner tonight?',
      'categoryId': 'category_food',
      'answerType': 1,
      'allowCustomOption': true,
      'status': 1,
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
    },
    {
      'id': 'poll_105',
      'question': 'Which features should we add to the app?',
      'categoryId': 'category_product',
      'answerType': 2,
      'allowCustomOption': true,
      'status': 1,
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
    },
    {
      'id': 'poll_106',
      'question': 'Which travel destination would you choose?',
      'categoryId': 'category_travel',
      'answerType': 1,
      'allowCustomOption': true,
      'status': 1,
      'options': [
        {
          'id': 'option_1019',
          'type': 2,
          'text': null,
          'imageUrl': 'https://example.com/images/goa.jpg',
          'sortOrder': 1,
          'isCustom': false,
        },
        {
          'id': 'option_1020',
          'type': 2,
          'text': null,
          'imageUrl': 'https://example.com/images/manali.jpg',
          'sortOrder': 2,
          'isCustom': false,
        },
        {
          'id': 'option_1021',
          'type': 2,
          'text': null,
          'imageUrl': 'https://example.com/images/jaipur.jpg',
          'sortOrder': 3,
          'isCustom': false,
        },
      ],
    },
  ];
}
