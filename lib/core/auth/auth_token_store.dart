import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';
import 'package:yakku/data/models/auth/token_response.dart';

/// Centralized access/refresh token cache.
///
/// Keeps tokens in memory for request attachment and persists to secure storage.
/// Call [hydrate] once during app startup / session restoration.
class AuthTokenStore {
  AuthTokenStore({required SecureStorageService secureStorage})
    : _secureStorage = secureStorage;

  final SecureStorageService _secureStorage;

  String? _accessToken;
  String? _refreshToken;
  bool _hydrated = false;

  bool get isHydrated => _hydrated;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  bool get hasRefreshToken =>
      _refreshToken != null && _refreshToken!.isNotEmpty;

  bool get hasSessionTokens => hasAccessToken && hasRefreshToken;

  /// Loads persisted tokens into memory. Safe to call more than once.
  Future<void> hydrate() async {
    _accessToken = await _secureStorage.read(StorageKeys.accessToken);
    _refreshToken = await _secureStorage.read(StorageKeys.refreshToken);
    _hydrated = true;
  }

  /// Atomically replaces both tokens in memory and secure storage.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _secureStorage.update(StorageKeys.accessToken, accessToken);
    await _secureStorage.update(StorageKeys.refreshToken, refreshToken);
    _hydrated = true;
  }

  Future<void> saveFromTokenResponse(TokenResponse tokens) {
    return saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  /// Clears in-memory and persisted tokens.
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.clearKeys([
      StorageKeys.accessToken,
      StorageKeys.refreshToken,
    ]);
    _hydrated = true;
  }

  /// Extracts the Bearer value from an Authorization header, if present.
  static String? bearerFromAuthorizationHeader(Object? header) {
    if (header is! String) return null;
    const prefix = 'Bearer ';
    if (!header.startsWith(prefix)) return null;
    final value = header.substring(prefix.length).trim();
    return value.isEmpty ? null : value;
  }
}
