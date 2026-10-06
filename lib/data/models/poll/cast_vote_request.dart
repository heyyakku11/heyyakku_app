class CastVoteRequest {
  final String pollId;
  final String? optionId;
  final String? customOption;
  final String? imageId;
  final String? reason;

  const CastVoteRequest({
    required this.pollId,
    this.optionId,
    this.customOption,
    this.imageId,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'pollId': pollId,
      if (optionId != null) 'optionId': optionId,
      if (customOption != null) 'customOption': customOption,
      if (imageId != null) 'imageId': imageId,
      if (reason != null) 'reason': reason,
    };
  }
}
