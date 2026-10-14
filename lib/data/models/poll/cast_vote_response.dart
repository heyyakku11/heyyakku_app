class CastVoteResponse {
  final String id;
  final String pollId;
  final String? pollOptionId;
  final String? customAnswer;
  final String? reason;
  final DateTime createdAt;

  const CastVoteResponse({
    required this.id,
    required this.pollId,
    required this.createdAt,
    this.pollOptionId,
    this.customAnswer,
    this.reason,
  });

  factory CastVoteResponse.fromJson(Map<String, dynamic> json) {
    return CastVoteResponse(
      id: json['id']?.toString() ?? '',
      pollId: json['pollId']?.toString() ?? '',
      pollOptionId: json['pollOptionId']?.toString(),
      customAnswer: json['customAnswer'] as String?,
      reason: json['reason'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
