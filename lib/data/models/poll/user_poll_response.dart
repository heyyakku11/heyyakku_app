class UserPollOptionResponse {
  final String id;
  final String text;
  final int voteCount;
  final double percentage;

  const UserPollOptionResponse({
    required this.id,
    required this.text,
    required this.voteCount,
    required this.percentage,
  });

  factory UserPollOptionResponse.fromJson(Map<String, dynamic> json) {
    return UserPollOptionResponse(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      voteCount: _asInt(json['voteCount']),
      percentage: _asDouble(json['percentage']),
    );
  }
}

class UserPollResponse {
  /// "poll" or "check": the asks list holds both, newest first.
  final String kind;
  final String pollId;
  final String shareCode;
  final String question;
  final String contentType;
  final String status;
  final String visibility;
  final DateTime createdAt;
  final int totalVoteCount;
  final int customAnswerCount;
  final int totalWhyCount;
  final List<UserPollOptionResponse> pollOptions;

  const UserPollResponse({
    this.kind = 'poll',
    required this.pollId,
    required this.question,
    required this.contentType,
    required this.status,
    required this.visibility,
    required this.createdAt,
    required this.totalVoteCount,
    required this.pollOptions,
    this.shareCode = '',
    this.customAnswerCount = 0,
    this.totalWhyCount = 0,
  });

  factory UserPollResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['pollOptions'] as List<dynamic>? ?? const [];
    return UserPollResponse(
      kind: json['kind'] as String? ?? 'poll',
      pollId: json['pollId']?.toString() ?? '',
      shareCode: json['shareCode'] as String? ?? '',
      question: json['question'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'question',
      status: json['status'] as String? ?? '',
      visibility: json['visibility'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      totalVoteCount: _asInt(json['totalVoteCount']),
      customAnswerCount: _asInt(json['customAnswerCount']),
      totalWhyCount: _asInt(json['totalWhyCount']),
      pollOptions: rawOptions
          .whereType<Map>()
          .map(
            (item) => UserPollOptionResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class UserPollsPage {
  final List<UserPollResponse> items;
  final String? nextCursor;
  final bool hasMore;

  const UserPollsPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
