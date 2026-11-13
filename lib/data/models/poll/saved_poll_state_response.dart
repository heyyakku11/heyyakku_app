class SavedPollStateResponse {
  final String pollId;
  final bool saved;

  const SavedPollStateResponse({required this.pollId, required this.saved});

  factory SavedPollStateResponse.fromJson(Map<String, dynamic> json) {
    return SavedPollStateResponse(
      // The saved-cards API calls it cardId (the card is a poll here).
      pollId: (json['cardId'] ?? json['pollId'])?.toString() ?? '',
      saved: json['saved'] as bool? ?? false,
    );
  }
}
