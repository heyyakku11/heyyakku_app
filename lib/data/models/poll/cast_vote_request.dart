class CastVoteRequest {
  final String shareCode;
  final String? optionId;
  final String? customAnswer;
  final String? reason;

  const CastVoteRequest({
    required this.shareCode,
    this.optionId,
    this.customAnswer,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'shareCode': shareCode,
      if (optionId != null) 'optionId': optionId,
      if (customAnswer != null) 'customAnswer': customAnswer,
      if (reason != null) 'reason': reason,
    };
  }
}
