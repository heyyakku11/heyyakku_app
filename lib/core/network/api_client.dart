import 'package:dio/dio.dart';
import 'package:yakku/core/auth/auth_token_store.dart';
import 'package:yakku/core/auth/token_refresh_service.dart';
import 'package:yakku/core/constants/api_constants.dart';
import 'package:yakku/core/network/api_performance_interceptor.dart';
import 'package:yakku/core/network/auth_interceptor.dart';

abstract final class ApiClient {
  static BaseOptions get _baseOptions => BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: const {'Content-Type': 'application/json'},
  );

  /// Unauthenticated client (OTP, refresh, logout).
  static Dio create() {
    final dio = Dio(_baseOptions);
    dio.interceptors.add(ApiPerformanceInterceptor());
    return dio;
  }

  /// Authenticated Dio with Bearer attachment and silent refresh on 401.
  ///
  /// Interceptor order: performance is registered first so [AuthInterceptor]
  /// runs first on errors (Dio invokes onError in reverse registration order).
  static Dio createAuthenticated({
    required AuthTokenStore tokenStore,
    required TokenRefreshService tokenRefreshService,
    required SessionExpiredCallback onSessionExpired,
  }) {
    final dio = Dio(_baseOptions);
    dio.interceptors.add(ApiPerformanceInterceptor());
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenStore: tokenStore,
        tokenRefreshService: tokenRefreshService,
        onSessionExpired: onSessionExpired,
      ),
    );
    return dio;
  }
}
