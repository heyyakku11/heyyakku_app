class PollOptionResponse {
  final String id;
  final String? text;
  final String? imageId;
  final String? secureUrl;
  final int sortOrder;
  final int voteCount;
  final double percentage;

  const PollOptionResponse({
    required this.id,
    required this.sortOrder,
    this.text,
    this.imageId,
    this.secureUrl,
    this.voteCount = 0,
    this.percentage = 0,
  });

  factory PollOptionResponse.fromJson(Map<String, dynamic> json) {
    return PollOptionResponse(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String?,
      imageId: json['imageId']?.toString(),
      secureUrl: json['secureUrl'] as String?,
      sortOrder: _asInt(json['sortOrder']),
      voteCount: _asInt(json['voteCount']),
      percentage: _asDouble(json['percentage']),
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
