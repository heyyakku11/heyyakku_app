class UserPollOptionResponse {
  final String id;
  final String? text;
  final int voteCount;
  final double percentage;

  const UserPollOptionResponse({
    required this.id,
    required this.voteCount,
    required this.percentage,
    this.text,
  });

  factory UserPollOptionResponse.fromJson(Map<String, dynamic> json) {
    return UserPollOptionResponse(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String?,
      voteCount: _asInt(json['voteCount']),
      percentage: _asDouble(json['percentage']),
    );
  }
}

class UserPollResponse {
  final String pollId;
  final String question;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final int totalVoteCount;
  final List<UserPollOptionResponse> pollOptions;

  const UserPollResponse({
    required this.pollId,
    required this.question,
    required this.status,
    required this.createdAt,
    required this.totalVoteCount,
    required this.pollOptions,
    this.expiresAt,
  });

  factory UserPollResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['pollOptions'] as List<dynamic>? ?? const [];
    return UserPollResponse(
      pollId: json['pollId']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      status: json['status'] as String? ?? '',
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      totalVoteCount: _asInt(json['totalVoteCount']),
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

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
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
