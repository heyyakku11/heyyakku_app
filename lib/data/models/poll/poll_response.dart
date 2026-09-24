import 'package:yakku/data/models/poll/poll_option_response.dart';

class PollResponse {
  final String id;
  final String question;
  final String shareToken;
  final String optionType;
  final DateTime expiresAt;
  final bool allowComments;
  final int totalVoteCount;
  final String? selectedOptionId;
  final List<PollOptionResponse> options;

  const PollResponse({
    required this.id,
    required this.question,
    required this.shareToken,
    required this.optionType,
    required this.totalVoteCount,
    required this.options,
    required this.expiresAt,
    required this.allowComments,
    this.selectedOptionId,
  });

  factory PollResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return PollResponse(
      id: json['id']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      shareToken: json['shareToken'] as String? ?? '',
      optionType: json['optionType'] as String? ?? 'text',
      expiresAt: _parseDate(json['expiresAt']) ?? DateTime.now(),
      allowComments: json['allowComments'] as bool? ?? false,
      totalVoteCount: _asInt(json['totalVoteCount']),
      selectedOptionId: json['selectedOptionId']?.toString(),
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
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
