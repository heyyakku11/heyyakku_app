import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_exception.dart';

/// Maps [DioException] / unknown errors into [ApiException] without leaking
/// sensitive headers or tokens.
abstract final class DioErrorMapper {
  static ApiException map(
    Object error, {
    String fallback = 'Something went wrong',
  }) {
    if (error is ApiException) return error;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.cancel:
          return ApiException(
            kind: ApiErrorKind.cancelled,
            message: 'Request cancelled',
            cause: error,
          );
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          return const ApiException(
            kind: ApiErrorKind.timeout,
            message: 'Request timed out. Please try again.',
          );
        case DioExceptionType.connectionError:
          return const ApiException(
            kind: ApiErrorKind.connection,
            message: 'No internet connection. Please check your network.',
          );
        case DioExceptionType.badCertificate:
          return const ApiException(
            kind: ApiErrorKind.connection,
            message: 'Secure connection failed. Please try again.',
          );
        case DioExceptionType.badResponse:
          return _fromStatus(
            statusCode: error.response?.statusCode,
            serverMessage: _serverMessage(error),
            serverCode: errorCodeFromBody(error.response?.data),
            fallback: fallback,
            cause: error,
          );
        case DioExceptionType.unknown:
          return ApiException(
            kind: ApiErrorKind.unknown,
            message: fallback,
            cause: error,
          );
      }
    }

    if (error is StateError) {
      return ApiException(
        kind: ApiErrorKind.unknown,
        message: error.message,
        cause: error,
      );
    }

    return ApiException(
      kind: ApiErrorKind.unknown,
      message: fallback,
      cause: error,
    );
  }

  static ApiException _fromStatus({
    required int? statusCode,
    required String? serverMessage,
    required String fallback,
    String? serverCode,
    Object? cause,
  }) {
    final kind = switch (statusCode) {
      400 => ApiErrorKind.badRequest,
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      409 => ApiErrorKind.conflict,
      422 => ApiErrorKind.validation,
      429 => ApiErrorKind.rateLimited,
      500 || 502 || 503 => ApiErrorKind.server,
      _ => ApiErrorKind.unknown,
    };

    final message = switch (kind) {
      ApiErrorKind.unauthorized =>
        serverMessage ?? 'Session expired. Please sign in again.',
      ApiErrorKind.forbidden =>
        serverMessage ?? 'You do not have permission to do that.',
      ApiErrorKind.notFound =>
        serverMessage ?? 'Requested resource was not found.',
      ApiErrorKind.rateLimited =>
        serverMessage ?? 'Too many requests. Please wait and try again.',
      ApiErrorKind.server =>
        serverMessage ?? 'Server error. Please try again later.',
      ApiErrorKind.validation ||
      ApiErrorKind.badRequest ||
      ApiErrorKind.conflict => serverMessage ?? fallback,
      _ => serverMessage ?? fallback,
    };

    return ApiException(
      kind: kind,
      message: message,
      statusCode: statusCode,
      code: serverCode,
      cause: cause,
    );
  }

  static String? errorCodeFromBody(dynamic data) {
    if (data is! Map) return null;

    String? fromValue(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      return null;
    }

    final direct = fromValue(data['code']) ?? fromValue(data['errorCode']);
    if (direct != null) return direct;

    final errors = data['errors'];
    if (errors is String) return fromValue(errors);
    if (errors is Map) {
      return fromValue(errors['code']) ?? fromValue(errors['errorCode']);
    }
    if (errors is List) {
      for (final item in errors) {
        if (item is String) {
          final value = fromValue(item);
          if (value != null) return value;
        } else if (item is Map) {
          final value = fromValue(item['code']) ?? fromValue(item['errorCode']);
          if (value != null) return value;
        }
      }
    }
    return null;
  }

  static String? _serverMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }
}
