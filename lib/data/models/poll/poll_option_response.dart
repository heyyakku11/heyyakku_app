class PollOptionResponse {
  final String id;
  final String? text;
  final int sortOrder;
  final int voteCount;
  final double percentage;

  /// Voters who gave a "why" reason for this option.
  final int whyCount;

  const PollOptionResponse({
    required this.id,
    required this.sortOrder,
    this.text,
    this.voteCount = 0,
    this.percentage = 0,
    this.whyCount = 0,
  });

  factory PollOptionResponse.fromJson(Map<String, dynamic> json) {
    return PollOptionResponse(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String?,
      sortOrder: _asInt(json['sortOrder']),
      voteCount: _asInt(json['voteCount']),
      percentage: _asDouble(json['percentage']),
      whyCount: _asInt(json['whyCount']),
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
