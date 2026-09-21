import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:yakku/core/auth/auth_token_store.dart';
import 'package:yakku/core/auth/token_refresh_service.dart';
import 'package:yakku/core/network/api_performance_interceptor.dart';
import 'package:yakku/core/network/api_routes.dart';

typedef SessionExpiredCallback = Future<void> Function();

/// Attaches Bearer tokens from [AuthTokenStore] and silently refreshes on 401.
///
/// Retry policy: at most one refresh-driven retry per request (`auth_retried`).
/// Concurrent 401s share one refresh via [TokenRefreshService] single-flight.
/// Uses [Interceptor] (not [QueuedInterceptor]) so a post-refresh retry that
/// still returns 401 cannot deadlock the interceptor error queue.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required AuthTokenStore tokenStore,
    required TokenRefreshService tokenRefreshService,
    required SessionExpiredCallback onSessionExpired,
  }) : _dio = dio,
       _tokenStore = tokenStore,
       _tokenRefreshService = tokenRefreshService,
       _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final AuthTokenStore _tokenStore;
  final TokenRefreshService _tokenRefreshService;
  final SessionExpiredCallback _onSessionExpired;

  static const _retriedKey = 'auth_retried';

  static final _skipAuthPaths = <String>{
    ApiRoutes.sendOtp,
    ApiRoutes.verifyOtp,
    ApiRoutes.refresh,
  };

  bool _shouldSkipAuth(RequestOptions options) {
    final path = options.path;
    return _skipAuthPaths.any((route) => path.contains(route));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_shouldSkipAuth(options)) {
      if (!_tokenStore.isHydrated) {
        await _tokenStore.hydrate();
      }
      final accessToken = _tokenStore.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final request = err.requestOptions;
    final alreadyRetried = request.extra[_retriedKey] == true;

    if (statusCode != 401 || alreadyRetried || _shouldSkipAuth(request)) {
      handler.next(err);
      return;
    }

    if (kDebugMode) {
      debugPrint('[AUTH] Access token rejected');
    }

    final requestToken = AuthTokenStore.bearerFromAuthorizationHeader(
      request.headers['Authorization'],
    );
    final currentToken = _tokenStore.accessToken;

    // Another queued 401 already refreshed — reuse new token, no second refresh.
    if (currentToken != null &&
        currentToken.isNotEmpty &&
        currentToken != requestToken) {
      try {
        if (kDebugMode) {
          debugPrint('[AUTH] Using freshly refreshed access token');
          debugPrint('[API] Retrying original request');
        }
        ApiPerformanceInterceptor.markRetryStarted(request);
        request.headers['Authorization'] = 'Bearer $currentToken';
        request.extra[_retriedKey] = true;
        final response = await _dio.fetch<dynamic>(request);
        handler.resolve(response);
      } catch (retryError) {
        handler.next(retryError is DioException ? retryError : err);
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('[AUTH] Refresh started');
      }
      final refreshStarted = DateTime.now().millisecondsSinceEpoch;
      final tokens = await _tokenRefreshService.refresh();
      final refreshMs = DateTime.now().millisecondsSinceEpoch - refreshStarted;
      ApiPerformanceInterceptor.markRefreshDuration(request, refreshMs);

      if (kDebugMode) {
        debugPrint('[API] Retrying original request');
      }
      ApiPerformanceInterceptor.markRetryStarted(request);
      request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      request.extra[_retriedKey] = true;

      try {
        final response = await _dio.fetch<dynamic>(request);
        handler.resolve(response);
      } on DioException catch (retryError) {
        // Refresh succeeded but retry failed — do not refresh again.
        handler.next(retryError);
      }
    } catch (_) {
      // Refresh itself failed — invalidate session.
      await _onSessionExpired();
      handler.next(err);
    }
  }
}
