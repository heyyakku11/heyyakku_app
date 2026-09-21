import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Development-only timing for API requests. Never logs tokens or auth headers.
class ApiPerformanceInterceptor extends Interceptor {
  static const _startKey = 'api_perf_start_ms';
  static const _refreshMsKey = 'api_perf_refresh_ms';
  static const _retryStartKey = 'api_perf_retry_start_ms';

  static void markRefreshDuration(RequestOptions options, int refreshMs) {
    options.extra[_refreshMsKey] = refreshMs;
  }

  static void markRetryStarted(RequestOptions options) {
    options.extra[_retryStartKey] = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
      debugPrint('[API] ${options.method} ${_path(options)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logComplete(response.requestOptions, statusCode: response.statusCode);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logComplete(
        err.requestOptions,
        statusCode: err.response?.statusCode,
        failed: true,
        errorType: err.type.name,
      );
    }
    handler.next(err);
  }

  void _logComplete(
    RequestOptions options, {
    int? statusCode,
    bool failed = false,
    String? errorType,
  }) {
    final startMs = options.extra[_startKey];
    if (startMs is! int) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final totalMs = now - startMs;
    final refreshMs = options.extra[_refreshMsKey];
    final retryStart = options.extra[_retryStartKey];

    if (statusCode != null) {
      debugPrint('[API] Response: $statusCode');
    } else if (failed && errorType != null) {
      debugPrint('[API] Failed: $errorType');
    }

    if (refreshMs is int) {
      debugPrint('[AUTH] Refresh completed: ${refreshMs}ms');
    }
    if (retryStart is int) {
      debugPrint('[API] Retry duration: ${now - retryStart}ms');
    }
    debugPrint('[API] Total duration: ${totalMs}ms');
  }

  static String _path(RequestOptions options) {
    final uri = options.uri;
    return uri.hasQuery ? '${uri.path}?…' : uri.path;
  }
}
