import 'package:yakku/core/auth/auth_token_store.dart';
import 'package:yakku/core/auth/jwt_access_token.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/models/auth/refresh_token_request.dart';
import 'package:yakku/data/models/auth/token_response.dart';

/// Refreshes access + refresh tokens with a single-flight lock.
///
/// Concurrent callers share one in-flight refresh. After completion the lock
/// clears so a later independent 401 can refresh again — but never loops for
/// the same retried request (see [AuthInterceptor] retry flag).
class TokenRefreshService {
  TokenRefreshService({
    required AuthTokenStore tokenStore,
    required AuthRemoteDataSource authRemote,
  }) : _tokenStore = tokenStore,
       _authRemote = authRemote;

  final AuthTokenStore _tokenStore;
  final AuthRemoteDataSource _authRemote;

  Future<TokenResponse>? _inFlight;

  /// True while a refresh is running (including waiters on the same future).
  bool get isRefreshing => _inFlight != null;

  /// How soon before `exp` a token is treated as stale and rotated early.
  static const defaultBufferSeconds = 60;

  Future<TokenResponse> refresh() {
    return _inFlight ??= _doRefresh().whenComplete(() {
      _inFlight = null;
    });
  }

  /// Returns a usable access token, refreshing first when the current JWT is
  /// expired or within [bufferSeconds] of expiry.
  ///
  /// Returns null when there is no access token. Throws when a required
  /// refresh fails (caller should end the session).
  Future<String?> ensureFreshAccessToken({
    int bufferSeconds = defaultBufferSeconds,
  }) async {
    if (!_tokenStore.isHydrated) {
      await _tokenStore.hydrate();
    }

    var token = _tokenStore.accessToken;
    if (token == null || token.isEmpty) return null;

    if (!JwtAccessToken.needsRefresh(token, bufferSeconds: bufferSeconds)) {
      return token;
    }

    if (!_tokenStore.hasRefreshToken) {
      throw StateError('Access token expired and no refresh token available');
    }

    final tokens = await refresh();
    return tokens.accessToken;
  }

  Future<TokenResponse> _doRefresh() async {
    if (!_tokenStore.isHydrated) {
      await _tokenStore.hydrate();
    }

    final refreshToken = _tokenStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No refresh token available');
    }

    final tokens = await _authRemote.refresh(
      RefreshTokenRequest(refreshToken: refreshToken),
    );

    await _tokenStore.saveFromTokenResponse(tokens);
    return tokens;
  }
}
