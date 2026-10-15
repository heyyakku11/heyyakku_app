import 'package:yakku/data/models/home/home_feed_response.dart';

/// Dummy home feed — same shape as the API JSON response.
final homeFeedResponse = HomeFeedResponse.fromJson(const {
  'mirrorChecks': [
    {
      'title': 'Mirror Check',
      'question': 'Do people like me, or just like having me around?',
      'backgroundColor': '#FFE0E8',
      'foregroundColor': '#21191D',
      'chipColor': '#F6F1F3',
      'accentColor': '#D02E62',
      'sticker': 'No filters.\nJust truth.',
      'options': [
        'Genuinely like you',
        'Like having you around',
        'Both',
      ],
    },
    {
      'title': 'Trust Check',
      'question': 'If I told you a secret, how long before someone else knows?',
      'backgroundColor': '#DDF3E4',
      'foregroundColor': '#21191D',
      'chipColor': '#FFFFFF',
      'accentColor': '#D02E62',
      'sticker': 'Keep it real.',
      'options': [
        'Never',
        'A week',
        'Already told',
      ],
    },
    {
      'title': 'Vibe Check',
      'question': 'When I walk in, does the energy go up?',
      'backgroundColor': '#ECE3FF',
      'foregroundColor': '#21191D',
      'chipColor': '#FFFFFF',
      'accentColor': '#D02E62',
      'sticker': 'Read the room.',
      'options': ['Up', 'Down', 'Same'],
    },
    {
      'title': 'Loyalty Check',
      'question': 'Would you still pick me if it got awkward?',
      'backgroundColor': '#FFEFC2',
      'foregroundColor': '#21191D',
      'chipColor': '#FFFFFF',
      'accentColor': '#D02E62',
      'sticker': 'Say it plain.',
      'options': ['Always', 'Depends', 'Probably not'],
    },
  ],
  'questionsWorthAsking': [
    {
      'question': 'Honestly, am I hard to be close to?',
      'options': ['Not at all', 'A little', 'Yes, but worth it'],
    },
    {
      'question': 'If we stopped talking tomorrow, would you notice?',
      'options': ['Instantly', 'In a week', 'Honestly, no'],
    },
    {
      'question': 'Would you tell me if I hurt you?',
      'options': ['Right away', 'Eventually', "I'd stay quiet"],
    },
    {
      'question': 'Do you think I try too hard to fit in?',
      'options': ['Never', 'Sometimes', 'Yeah, a lot'],
    },
    {
      'question': 'Would you hang out with me one-on-one?',
      'options': ['Always', 'Sometimes', 'Not really'],
    },
    {
      'question': 'Have you ever fake-laughed at something I said?',
      'options': ['Never', 'Once or twice', 'More times than I can count'],
    },
    {
      'question': 'Am I someone you'd go to for advice?',
      'options': ['Definitely', 'Maybe', 'No, not really'],
    },
  ],
});

final mirrorChecks = homeFeedResponse.mirrorChecks;
final questionsWorthAsking = homeFeedResponse.questionsWorthAsking;
