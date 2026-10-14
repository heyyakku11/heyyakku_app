class CastVoteRequest {
  final String pollId;
  final String? pollOptionId;
  final String? customAnswer;
  final String? reason;

  const CastVoteRequest({
    required this.pollId,
    this.pollOptionId,
    this.customAnswer,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'pollId': pollId,
      if (pollOptionId != null) 'pollOptionId': pollOptionId,
      if (customAnswer != null) 'customAnswer': customAnswer,
      if (reason != null) 'reason': reason,
    };
  }
}
