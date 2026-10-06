class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic errors;
  final dynamic meta;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromData,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: rawData == null || fromData == null ? null : fromData(rawData),
      errors: json['errors'],
      meta: json['meta'],
    );
  }
}

({String? nextCursor, bool hasMore}) cursorFromMeta(dynamic meta) {
  String? nextCursor;
  var hasMore = false;
  if (meta is Map) {
    final metaMap = Map<String, dynamic>.from(meta);
    nextCursor = metaMap['nextCursor'] as String?;
    hasMore = metaMap['hasMore'] as bool? ?? false;
  }
  return (nextCursor: nextCursor, hasMore: hasMore);
}
