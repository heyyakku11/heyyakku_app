int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

class UserCheckOptionResponse {
  const UserCheckOptionResponse({
    required this.id,
    required this.text,
    this.votes,
    this.whyCount,
  });

  final String id;
  final String text;

  /// Null until the caller is allowed to see results.
  final int? votes;

  /// Voters who gave a reason; null until results are visible.
  final int? whyCount;

  factory UserCheckOptionResponse.fromJson(Map<String, dynamic> json) {
    return UserCheckOptionResponse(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      votes: _asInt(json['votes']),
      whyCount: _asInt(json['whyCount']),
    );
  }
}

/// A check the user made, from `POST /checks/make` and `GET /checks/mine`.
class UserCheckResponse {
  const UserCheckResponse({
    required this.id,
    required this.checkId,
    required this.title,
    required this.question,
    required this.backgroundColor,
    required this.sticker,
    required this.shareCode,
    required this.isOwner,
    required this.options,
    this.myVoteOptionId,
    this.myCustomAnswer,
    this.totalVotes,
    this.customAnswerVotes,
    this.createdAt,
  });

  final String id;
  final String checkId;
  final String title;
  final String question;
  final String backgroundColor;
  final String sticker;
  final String shareCode;
  final bool isOwner;
  final String? myVoteOptionId;
  final String? myCustomAnswer;
  final int? totalVotes;
  final int? customAnswerVotes;
  final List<UserCheckOptionResponse> options;
  final DateTime? createdAt;

  bool get resultsVisible => totalVotes != null;

  factory UserCheckResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return UserCheckResponse(
      id: json['id']?.toString() ?? '',
      checkId: json['checkId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      backgroundColor: json['backgroundColor']?.toString() ?? '',
      sticker: json['sticker']?.toString() ?? '',
      shareCode: json['shareCode']?.toString() ?? '',
      isOwner: json['isOwner'] as bool? ?? false,
      myVoteOptionId: json['myVoteOptionId']?.toString(),
      myCustomAnswer: json['myCustomAnswer']?.toString(),
      totalVotes: _asInt(json['totalVotes']),
      customAnswerVotes: _asInt(json['customAnswerVotes']),
      options: [
        for (final option in rawOptions.whereType<Map>())
          UserCheckOptionResponse.fromJson(Map<String, dynamic>.from(option)),
      ],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
