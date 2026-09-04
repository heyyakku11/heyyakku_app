class AnonymousUser {
  const AnonymousUser({
    required this.id,
    this.displayName = 'Anonymous User',
    this.avatarSeed = 0,
    this.questionsCount = 0,
    this.votesReceived = 0,
    this.answersCount = 0,
  });

  final String id;
  final String displayName;
  final int avatarSeed;
  final int questionsCount;
  final int votesReceived;
  final int answersCount;

  AnonymousUser copyWith({
    String? id,
    String? displayName,
    int? avatarSeed,
    int? questionsCount,
    int? votesReceived,
    int? answersCount,
  }) {
    return AnonymousUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      questionsCount: questionsCount ?? this.questionsCount,
      votesReceived: votesReceived ?? this.votesReceived,
      answersCount: answersCount ?? this.answersCount,
    );
  }
}
