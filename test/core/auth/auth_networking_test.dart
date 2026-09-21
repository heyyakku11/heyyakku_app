import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/auth/auth_token_store.dart';
import 'package:yakku/core/auth/token_refresh_service.dart';
import 'package:yakku/core/auth/user_preferences.dart';
import 'package:yakku/core/network/api_client.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/models/auth/logout_request.dart';
import 'package:yakku/data/models/auth/refresh_token_request.dart';
import 'package:yakku/data/models/auth/send_otp_data.dart';
import 'package:yakku/data/models/auth/send_otp_request_model.dart';
import 'package:yakku/data/models/auth/token_response.dart';
import 'package:yakku/data/models/auth/verify_otp_data.dart';
import 'package:yakku/data/models/auth/verify_otp_request_model.dart';

class _RecordingAuthRemote implements AuthRemoteDataSource {
  int refreshCalls = 0;
  Object? refreshError;
  Duration refreshDelay = Duration.zero;

  @override
  Future<SendOtpData> sendOtp(SendOtpRequestModel request) async {
    return const SendOtpData(purpose: 'Registration', expiresInSeconds: 300);
  }

  @override
  Future<VerifyOtpData> verifyOtp(VerifyOtpRequestModel request) async {
    throw UnimplementedError();
  }

  @override
  Future<TokenResponse> refresh(RefreshTokenRequest request) async {
    refreshCalls++;
    if (refreshDelay > Duration.zero) {
      await Future<void>.delayed(refreshDelay);
    }
    if (refreshError != null) {
      throw refreshError!;
    }
    return TokenResponse(
      accessToken: 'access-$refreshCalls',
      refreshToken: 'refresh-$refreshCalls',
      accessTokenExpiresInSeconds: 900,
      refreshTokenExpiresInSeconds: 604800,
    );
  }

  @override
  Future<void> logout(
    LogoutRequestModel request, {
    String? accessToken,
  }) async {}
}

void main() {
  group('AuthTokenStore', () {
    test(
      'hydrate loads tokens into memory without repeated storage reads',
      () async {
        final storage = SecureStorageService.inMemory({
          StorageKeys.accessToken: 'a1',
          StorageKeys.refreshToken: 'r1',
        });
        final store = AuthTokenStore(secureStorage: storage);

        await store.hydrate();

        expect(store.accessToken, 'a1');
        expect(store.refreshToken, 'r1');
        expect(store.hasSessionTokens, isTrue);
      },
    );

    test('clear removes memory and persisted tokens', () async {
      final storage = SecureStorageService.inMemory({
        StorageKeys.accessToken: 'a1',
        StorageKeys.refreshToken: 'r1',
      });
      final store = AuthTokenStore(secureStorage: storage);
      await store.hydrate();

      await store.clear();

      expect(store.accessToken, isNull);
      expect(store.refreshToken, isNull);
      expect(await storage.read(StorageKeys.accessToken), isNull);
      expect(await storage.read(StorageKeys.refreshToken), isNull);
    });
  });

  group('TokenRefreshService', () {
    test('concurrent refresh calls share a single remote refresh', () async {
      final storage = SecureStorageService.inMemory({
        StorageKeys.accessToken: 'old-access',
        StorageKeys.refreshToken: 'old-refresh',
      });
      final store = AuthTokenStore(secureStorage: storage);
      await store.hydrate();

      final authRemote = _RecordingAuthRemote()
        ..refreshDelay = const Duration(milliseconds: 40);
      final service = TokenRefreshService(
        tokenStore: store,
        authRemote: authRemote,
      );

      final results = await Future.wait([
        service.refresh(),
        service.refresh(),
        service.refresh(),
      ]);

      expect(authRemote.refreshCalls, 1);
      expect(results.every((t) => t.accessToken == 'access-1'), isTrue);
      expect(store.accessToken, 'access-1');
      expect(store.refreshToken, 'refresh-1');
    });

    test('refresh failure leaves callers with the same error', () async {
      final storage = SecureStorageService.inMemory({
        StorageKeys.accessToken: 'old-access',
        StorageKeys.refreshToken: 'old-refresh',
      });
      final store = AuthTokenStore(secureStorage: storage);
      await store.hydrate();

      final authRemote = _RecordingAuthRemote()
        ..refreshError = StateError('refresh failed');
      final service = TokenRefreshService(
        tokenStore: store,
        authRemote: authRemote,
      );

      await expectLater(service.refresh(), throwsStateError);
      expect(authRemote.refreshCalls, 1);
    });
  });

  group('AuthInterceptor via ApiClient', () {
    late Dio dio;
    late AuthTokenStore tokenStore;
    late _RecordingAuthRemote authRemote;
    late TokenRefreshService refreshService;
    var sessionExpiredCalls = 0;

    setUp(() async {
      sessionExpiredCalls = 0;
      final storage = SecureStorageService.inMemory({
        StorageKeys.accessToken: 'expired-access',
        StorageKeys.refreshToken: 'valid-refresh',
      });
      tokenStore = AuthTokenStore(secureStorage: storage);
      await tokenStore.hydrate();
      authRemote = _RecordingAuthRemote();
      refreshService = TokenRefreshService(
        tokenStore: tokenStore,
        authRemote: authRemote,
      );
      dio = ApiClient.createAuthenticated(
        tokenStore: tokenStore,
        tokenRefreshService: refreshService,
        onSessionExpired: () async {
          sessionExpiredCalls++;
          await tokenStore.clear();
        },
      );
    });

    test('A: valid access token → success without refresh', () async {
      dio.httpClientAdapter = _Adapter((options) async {
        expect(options.headers['Authorization'], 'Bearer expired-access');
        return ResponseBody.fromString(
          '{"ok":true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await dio.get<Map<String, dynamic>>('/api/v1/polls');
      expect(response.statusCode, 200);
      expect(authRemote.refreshCalls, 0);
    });

    test('B: 401 → refresh → retry → success', () async {
      var calls = 0;
      dio.httpClientAdapter = _Adapter((options) async {
        calls++;
        if (calls == 1) {
          return ResponseBody.fromString('{"message":"expired"}', 401);
        }
        expect(options.headers['Authorization'], 'Bearer access-1');
        expect(options.extra['auth_retried'], isTrue);
        return ResponseBody.fromString(
          '{"ok":true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await dio.get<Map<String, dynamic>>('/api/v1/polls');
      expect(response.statusCode, 200);
      expect(authRemote.refreshCalls, 1);
      expect(sessionExpiredCalls, 0);
    });

    test('C: 401 → refresh failure → session cleared', () async {
      authRemote.refreshError = DioException(
        requestOptions: RequestOptions(path: ApiRoutes.refresh),
        response: Response(
          requestOptions: RequestOptions(path: ApiRoutes.refresh),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      dio.httpClientAdapter = _Adapter((options) async {
        return ResponseBody.fromString('{"message":"expired"}', 401);
      });

      await expectLater(
        dio.get<Map<String, dynamic>>('/api/v1/polls'),
        throwsA(isA<DioException>()),
      );
      expect(authRemote.refreshCalls, 1);
      expect(sessionExpiredCalls, 1);
      expect(tokenStore.accessToken, isNull);
    });

    test('D: concurrent 401s → one refresh → all succeed', () async {
      final pathCounts = <String, int>{};
      dio.httpClientAdapter = _Adapter((options) async {
        final path = options.path;
        pathCounts[path] = (pathCounts[path] ?? 0) + 1;
        final attempt = pathCounts[path]!;
        if (attempt == 1) {
          return ResponseBody.fromString('{"message":"expired"}', 401);
        }
        expect(options.headers['Authorization'], startsWith('Bearer access-'));
        return ResponseBody.fromString(
          '{"ok":true}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      authRemote.refreshDelay = const Duration(milliseconds: 30);

      final results = await Future.wait([
        dio.get<Map<String, dynamic>>('/api/v1/polls/a'),
        dio.get<Map<String, dynamic>>('/api/v1/polls/b'),
        dio.get<Map<String, dynamic>>('/api/v1/polls/c'),
      ]);

      expect(results.every((r) => r.statusCode == 200), isTrue);
      // Concurrent 401s share TokenRefreshService single-flight.
      expect(authRemote.refreshCalls, 1);
      expect(sessionExpiredCalls, 0);
    });

    test('E: retry still 401 → fail without infinite refresh loop', () async {
      dio.httpClientAdapter = _Adapter((options) async {
        return ResponseBody.fromString('{"message":"still unauthorized"}', 401);
      });

      await expectLater(
        dio.get<Map<String, dynamic>>('/api/v1/polls'),
        throwsA(isA<DioException>()),
      );
      expect(authRemote.refreshCalls, 1);
      expect(sessionExpiredCalls, 0);
    });

    test('G: connection error maps to ApiException', () {
      final mapped = DioErrorMapper.map(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(mapped.kind, ApiErrorKind.connection);
    });

    test('H: timeout maps to ApiException', () {
      final mapped = DioErrorMapper.map(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.receiveTimeout,
        ),
      );
      expect(mapped.kind, ApiErrorKind.timeout);
    });
  });

  group('AuthController logout', () {
    test('F: logout clears in-memory and persisted session', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = SecureStorageService.inMemory();
      final tokenStore = AuthTokenStore(secureStorage: storage);
      await tokenStore.saveTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );

      final authRemote = _RecordingAuthRemote();
      final controller = AuthController(
        userPreferences: UserPreferences(),
        tokenStore: tokenStore,
        authRemote: authRemote,
        isUserLogged: true,
        email: 'user@example.com',
        displayName: 'user',
      );
      await controller.userPreferences.setIsUserLogged(true);
      await controller.userPreferences.setEmail('user@example.com');

      await controller.logout();

      expect(controller.isLoggedIn, isFalse);
      expect(tokenStore.accessToken, isNull);
      expect(tokenStore.refreshToken, isNull);
      expect(await storage.read(StorageKeys.accessToken), isNull);
      expect(await storage.read(StorageKeys.refreshToken), isNull);
      expect(await controller.userPreferences.getIsUserLogged(), isFalse);
    });
  });
}

typedef _AdapterHandler = Future<ResponseBody> Function(RequestOptions options);

class _Adapter implements HttpClientAdapter {
  _Adapter(this._handler);

  final _AdapterHandler _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }
}
