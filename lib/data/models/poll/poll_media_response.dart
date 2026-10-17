class PollMediaResponse {
  final String mediaType;
  final String mimeType;
  final int fileSize;
  final int? durationMs;
  final String? url;
  final DateTime? urlExpiresAt;

  const PollMediaResponse({
    required this.mediaType,
    required this.mimeType,
    required this.fileSize,
    this.durationMs,
    this.url,
    this.urlExpiresAt,
  });

  factory PollMediaResponse.fromJson(Map<String, dynamic> json) {
    return PollMediaResponse(
      mediaType: json['mediaType'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      fileSize: _asInt(json['fileSize']),
      durationMs: json['durationMs'] == null
          ? null
          : _asInt(json['durationMs']),
      url: json['url'] as String?,
      urlExpiresAt: _parseDate(json['urlExpiresAt']),
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
