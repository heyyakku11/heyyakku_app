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
  });

  final String shareCode;
  final PersonalityCardStatus status;
  final List<PersonalityTrait> selfTraits;
  final int totalVotes;
  final int requiredVotes;

  bool get isCompleted => status == PersonalityCardStatus.completed;

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
    );
  }
}
