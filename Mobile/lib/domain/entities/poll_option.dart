class PollOption {
  const PollOption({
    required this.id,
    required this.pollId,
    required this.text,
    required this.position,
    this.voteCount = 0,
    this.isSomethingElse = false,
  });

  final String id;
  final String pollId;
  final String text;
  final int position;
  final int voteCount;
  final bool isSomethingElse;

  PollOption copyWith({
    String? id,
    String? pollId,
    String? text,
    int? position,
    int? voteCount,
    bool? isSomethingElse,
  }) {
    return PollOption(
      id: id ?? this.id,
      pollId: pollId ?? this.pollId,
      text: text ?? this.text,
      position: position ?? this.position,
      voteCount: voteCount ?? this.voteCount,
      isSomethingElse: isSomethingElse ?? this.isSomethingElse,
    );
  }
}
