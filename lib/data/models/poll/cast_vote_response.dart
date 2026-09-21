class CastVoteResponse {
  final String id;
  final String pollId;
  final String? pollOptionId;
  final String? customOptionText;
  final String? imageId;
  final String? reason;
  final DateTime createdAt;

  const CastVoteResponse({
    required this.id,
    required this.pollId,
    required this.createdAt,
    this.pollOptionId,
    this.customOptionText,
    this.imageId,
    this.reason,
  });

  factory CastVoteResponse.fromJson(Map<String, dynamic> json) {
    return CastVoteResponse(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      pollOptionId: json['pollOptionId'] as String?,
      customOptionText: json['customOptionText'] as String?,
      imageId: json['imageId'] as String?,
      reason: json['reason'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
