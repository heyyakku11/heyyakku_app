class CastVoteRequest {
  final String? optionId;
  final String? customOption;
  final String? imageId;
  final String? reason;

  const CastVoteRequest({
    this.optionId,
    this.customOption,
    this.imageId,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      if (optionId != null) 'optionId': optionId,
      if (customOption != null) 'customOption': customOption,
      if (imageId != null) 'imageId': imageId,
      if (reason != null) 'reason': reason,
    };
  }
}
