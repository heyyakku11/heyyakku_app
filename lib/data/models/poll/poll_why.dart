class PollWhy {
  final String id;
  final String authorName;
  final String text;
  final int likeCount;
  final String? optionId;

  const PollWhy({
    required this.id,
    required this.authorName,
    required this.text,
    this.likeCount = 0,
    this.optionId,
  });

  factory PollWhy.fromJson(Map<String, dynamic> json) {
    return PollWhy(
      id: json['id']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      likeCount: _asInt(json['likeCount']),
      optionId: _asNullableString(json['optionId']),
    );
  }

  static List<PollWhy> listFromJson(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => PollWhy.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.isEmpty) return null;
  return text;
}
