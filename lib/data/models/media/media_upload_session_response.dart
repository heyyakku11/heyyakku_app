class MediaUploadTargetResponse {
  final String method;
  final String url;
  final Map<String, String> headers;

  const MediaUploadTargetResponse({
    required this.method,
    required this.url,
    required this.headers,
  });

  factory MediaUploadTargetResponse.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'];
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        headers['$key'] = '$value';
      });
    }
    return MediaUploadTargetResponse(
      method: json['method'] as String? ?? 'PUT',
      url: json['url'] as String? ?? '',
      headers: headers,
    );
  }
}

class MediaUploadSessionResponse {
  final String sessionId;
  final String status;
  final String mediaType;
  final String mimeType;
  final String objectKey;
  final int? expectedFileSize;
  final int? actualFileSize;
  final int? durationMs;
  final int selectionVersion;
  final MediaUploadTargetResponse? upload;
  final DateTime expiresAt;
  final String? failureReason;

  const MediaUploadSessionResponse({
    required this.sessionId,
    required this.status,
    required this.mediaType,
    required this.mimeType,
    required this.objectKey,
    required this.selectionVersion,
    required this.expiresAt,
    this.expectedFileSize,
    this.actualFileSize,
    this.durationMs,
    this.upload,
    this.failureReason,
  });

  factory MediaUploadSessionResponse.fromJson(Map<String, dynamic> json) {
    final rawUpload = json['upload'];
    return MediaUploadSessionResponse(
      sessionId: json['sessionId']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      objectKey: json['objectKey'] as String? ?? '',
      expectedFileSize: _asIntOrNull(json['expectedFileSize']),
      actualFileSize: _asIntOrNull(json['actualFileSize']),
      durationMs: _asIntOrNull(json['durationMs']),
      selectionVersion: _asInt(json['selectionVersion']),
      upload: rawUpload is Map
          ? MediaUploadTargetResponse.fromJson(
              Map<String, dynamic>.from(rawUpload),
            )
          : null,
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      failureReason: json['failureReason'] as String?,
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  return _asInt(value);
}
