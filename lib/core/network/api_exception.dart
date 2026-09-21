/// Predictable, UI-safe API / network failures.
enum ApiErrorKind {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,
  timeout,
  connection,
  cancelled,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.code,
    this.cause,
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;
  final String? code;
  final Object? cause;

  bool get isAuthFailure =>
      kind == ApiErrorKind.unauthorized || kind == ApiErrorKind.forbidden;

  @override
  String toString() => 'ApiException($kind, $statusCode, $code): $message';
}
