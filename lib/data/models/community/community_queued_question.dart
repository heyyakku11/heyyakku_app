import 'package:yakku/data/models/personality/personality_card.dart';

/// Fixed category codes for queued community questions (server allow-list).
abstract final class CommunityQueuedQuestionCategories {
  static const friendships = 'friendships';
  static const career = 'career';
  static const family = 'family';
  static const love = 'love';
  static const money = 'money';

  static const all = <String>[
    friendships,
    career,
    family,
    love,
    money,
  ];

  static const labels = <String, String>{
    friendships: 'Friendships',
    career: 'Career',
    family: 'Family',
    love: 'Love',
    money: 'Money',
  };

  static String label(String code) =>
      labels[code.toLowerCase()] ?? code;
}

/// A question the user queued for Community before it opens.
class CommunityQueuedQuestion {
  const CommunityQueuedQuestion({
    required this.id,
    required this.question,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.personalityTraits = const [],
  });

  final String id;
  final String question;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Crowd-top traits when the owner's completed card has shareToCommunity.
  final List<PersonalityTrait> personalityTraits;

  static const maxPerUser = 3;
  static const questionMaxLength = 280;

  factory CommunityQueuedQuestion.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>? ?? const [];
    final rawTraits = json['personalityTraits'] as List<dynamic>? ?? const [];
    return CommunityQueuedQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      tags: [
        for (final tag in rawTags)
          if (tag != null) tag.toString(),
      ],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      personalityTraits: [
        for (final trait in rawTraits)
          if (trait is Map<String, dynamic>) PersonalityTrait.fromJson(trait),
      ],
    );
  }

  Map<String, dynamic> toUpsertBody() => {
        'question': question,
        'tags': tags,
      };
}
