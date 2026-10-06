import 'package:yakku/data/models/poll/poll_option_response.dart';

class PollResponse {
  final String id;
  final String question;
  final String shareToken;
  final String optionType;
  final DateTime? expiresAt;
  final bool allowComments;
  final int totalVoteCount;
  final String? selectedOptionId;
  final List<PollOptionResponse> options;
  final List<String> categories;

  const PollResponse({
    required this.id,
    required this.question,
    required this.shareToken,
    required this.optionType,
    required this.totalVoteCount,
    required this.options,
    required this.allowComments,
    this.expiresAt,
    this.selectedOptionId,
    this.categories = const [],
  });

  factory PollResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return PollResponse(
      id: json['id']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      shareToken: json['shareToken'] as String? ?? '',
      optionType: json['optionType'] as String? ?? 'text',
      expiresAt: _parseDate(json['expiresAt']),
      allowComments: json['allowComments'] as bool? ?? false,
      totalVoteCount: _asInt(json['totalVoteCount']),
      selectedOptionId: json['selectedOptionId']?.toString(),
      categories: _categoryNames(json),
      options: rawOptions
          .map(
            (item) => PollOptionResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static List<String> _categoryNames(Map<String, dynamic> json) {
    final names = <String>[];

    void addName(Object? value) {
      final name = value?.toString().trim() ?? '';
      if (name.isEmpty || names.contains(name)) return;
      names.add(name);
    }

    void addCategory(Object? value) {
      if (value is Map) {
        addName(value['name'] ?? value['slug']);
        return;
      }
      if (value is String) addName(value);
    }

    final rawCategories = json['categories'];
    if (rawCategories is List) {
      for (final item in rawCategories) {
        addCategory(item);
      }
    }
    addCategory(json['category']);

    return List<String>.unmodifiable(names);
  }
}

class PollsPage {
  final List<PollResponse> items;
  final String? nextCursor;
  final bool hasMore;

  const PollsPage({required this.items, this.nextCursor, this.hasMore = false});
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
