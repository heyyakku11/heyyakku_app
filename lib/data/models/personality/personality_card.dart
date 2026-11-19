/// A predefined trait a friend can pick: `GET /api/v1/personality/traits`.
class PersonalityTrait {
  const PersonalityTrait({required this.id, required this.name});

  final String id;
  final String name;

  factory PersonalityTrait.fromJson(Map<String, dynamic> json) {
    return PersonalityTrait(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

/// Where the card is in its life: not shared yet, collecting friends' votes,
/// or done.
enum PersonalityCardStatus {
  draft,
  collecting,
  completed;

  static PersonalityCardStatus parse(String? value) {
    return switch (value?.toLowerCase()) {
      'collecting' => PersonalityCardStatus.collecting,
      'completed' => PersonalityCardStatus.completed,
      _ => PersonalityCardStatus.draft,
    };
  }
}

/// What `POST /api/v1/personality-cards/me/self-assessment` returns.
class PersonalitySelfAssessment {
  const PersonalitySelfAssessment({
    required this.shareCode,
    required this.status,
  });

  final String shareCode;
  final PersonalityCardStatus status;

  factory PersonalitySelfAssessment.fromJson(Map<String, dynamic> json) {
    return PersonalitySelfAssessment(
      shareCode: json['shareCode'] as String? ?? '',
      status: PersonalityCardStatus.parse(json['status'] as String?),
    );
  }
}

/// The signed-in user's own card: `GET /api/v1/personality-cards/me`.
class PersonalityCard {
  const PersonalityCard({
    required this.shareCode,
    required this.status,
    required this.selfTraits,
    required this.totalVotes,
    required this.requiredVotes,
    this.shareToCommunity = true,
  });

  final String shareCode;
  final PersonalityCardStatus status;
  final List<PersonalityTrait> selfTraits;
  final int totalVotes;
  final int requiredVotes;

  /// Whether the final result (what friends picked) is shared in the
  /// community. On by default; the owner can change it once the card is
  /// completed.
  final bool shareToCommunity;

  bool get isCompleted => status == PersonalityCardStatus.completed;

  PersonalityCard copyWith({
    String? shareCode,
    PersonalityCardStatus? status,
    List<PersonalityTrait>? selfTraits,
    int? totalVotes,
    int? requiredVotes,
    bool? shareToCommunity,
  }) {
    return PersonalityCard(
      shareCode: shareCode ?? this.shareCode,
      status: status ?? this.status,
      selfTraits: selfTraits ?? this.selfTraits,
      totalVotes: totalVotes ?? this.totalVotes,
      requiredVotes: requiredVotes ?? this.requiredVotes,
      shareToCommunity: shareToCommunity ?? this.shareToCommunity,
    );
  }

  factory PersonalityCard.fromJson(Map<String, dynamic> json) {
    final traits = json['selfTraits'];
    return PersonalityCard(
      shareCode: json['shareCode'] as String? ?? '',
      status: PersonalityCardStatus.parse(json['status'] as String?),
      selfTraits: [
        if (traits is List)
          for (final trait in traits)
            if (trait is Map<String, dynamic>) PersonalityTrait.fromJson(trait),
      ],
      totalVotes: json['totalVotes'] as int? ?? 0,
      requiredVotes: json['requiredVotes'] as int? ?? 0,
      shareToCommunity: json['shareToCommunity'] as bool? ?? true,
    );
  }
}

/// A friend's card as a voter sees it:
/// `GET /api/v1/personality-cards/{shareCode}`. It never carries the owner's
/// own picks or any voter details.
class SharedPersonalityCard {
  const SharedPersonalityCard({
    required this.shareCode,
    required this.ownerAnonymousName,
    required this.status,
    required this.isOwner,
    required this.hasVoted,
    required this.canVote,
    required this.totalVotes,
    required this.requiredVotes,
  });

  final String shareCode;
  final String ownerAnonymousName;
  final PersonalityCardStatus status;

  /// The signed-in caller owns this card.
  final bool isOwner;

  /// The caller has already voted on it.
  final bool hasVoted;

  /// The caller could vote right now.
  final bool canVote;
  final int totalVotes;
  final int requiredVotes;

  SharedPersonalityCard copyWith({
    PersonalityCardStatus? status,
    bool? isOwner,
    bool? hasVoted,
    bool? canVote,
  }) {
    return SharedPersonalityCard(
      shareCode: shareCode,
      ownerAnonymousName: ownerAnonymousName,
      status: status ?? this.status,
      isOwner: isOwner ?? this.isOwner,
      hasVoted: hasVoted ?? this.hasVoted,
      canVote: canVote ?? this.canVote,
      totalVotes: totalVotes,
      requiredVotes: requiredVotes,
    );
  }

  factory SharedPersonalityCard.fromJson(Map<String, dynamic> json) {
    return SharedPersonalityCard(
      shareCode: json['shareCode'] as String? ?? '',
      ownerAnonymousName: json['ownerAnonymousName'] as String? ?? '',
      status: PersonalityCardStatus.parse(json['status'] as String?),
      isOwner: json['isOwner'] as bool? ?? false,
      hasVoted: json['hasVoted'] as bool? ?? false,
      canVote: json['canVote'] as bool? ?? false,
      totalVotes: json['totalVotes'] as int? ?? 0,
      requiredVotes: json['requiredVotes'] as int? ?? 0,
    );
  }
}

/// What `POST /api/v1/personality-cards/{shareCode}/votes` returns.
class PersonalityVoteResult {
  const PersonalityVoteResult({
    required this.shareCode,
    required this.cardStatus,
    required this.totalVotes,
    required this.requiredVotes,
  });

  final String shareCode;
  final PersonalityCardStatus cardStatus;
  final int totalVotes;
  final int requiredVotes;

  factory PersonalityVoteResult.fromJson(Map<String, dynamic> json) {
    return PersonalityVoteResult(
      shareCode: json['shareCode'] as String? ?? '',
      cardStatus: PersonalityCardStatus.parse(json['cardStatus'] as String?),
      totalVotes: json['totalVotes'] as int? ?? 0,
      requiredVotes: json['requiredVotes'] as int? ?? 0,
    );
  }
}

/// One trait with how many friends picked it.
class PersonalityTraitCount {
  const PersonalityTraitCount({
    required this.id,
    required this.name,
    required this.votes,
  });

  final String id;
  final String name;
  final int votes;

  factory PersonalityTraitCount.fromJson(Map<String, dynamic> json) {
    return PersonalityTraitCount(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
    );
  }
}

/// "You vs the crowd": `GET /api/v1/personality-cards/{shareCode}/results`,
/// available once the card is completed.
class PersonalityResults {
  const PersonalityResults({
    required this.totalVotes,
    required this.crowdTopTraits,
    this.selfTraits = const [],
    this.commonTraits = const [],
    this.shareToCommunity = true,
  });

  final int totalVotes;

  /// What friends picked most, most-picked first.
  final List<PersonalityTraitCount> crowdTopTraits;

  /// The owner's own three guesses.
  final List<PersonalityTrait> selfTraits;

  /// Own guesses that friends also picked most.
  final List<PersonalityTrait> commonTraits;

  /// Whether the final result is shared in the community.
  final bool shareToCommunity;

  factory PersonalityResults.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = json[key];
      return [
        if (raw is List)
          for (final item in raw)
            if (item is Map<String, dynamic>) parse(item),
      ];
    }

    return PersonalityResults(
      totalVotes: json['totalVotes'] as int? ?? 0,
      crowdTopTraits: list('crowdTopTraits', PersonalityTraitCount.fromJson),
      selfTraits: list('selfSelectedTraits', PersonalityTrait.fromJson),
      commonTraits: list('commonTraits', PersonalityTrait.fromJson),
      shareToCommunity: json['shareToCommunity'] as bool? ?? true,
    );
  }
}
