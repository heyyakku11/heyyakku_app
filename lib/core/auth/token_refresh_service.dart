import 'package:yakku/core/auth/auth_token_store.dart';
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

  Future<TokenResponse> refresh() {
    return _inFlight ??= _doRefresh().whenComplete(() {
      _inFlight = null;
    });
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
