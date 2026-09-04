class PollVote {
  const PollVote({
    required this.id,
    required this.pollId,
    required this.voterId,
    required this.optionIds,
    required this.createdAt,
  });

  final String id;
  final String pollId;
  final String voterId;
  final List<String> optionIds;
  final DateTime createdAt;
}
