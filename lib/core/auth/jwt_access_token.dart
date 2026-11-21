import 'dart:convert';

/// Helpers for reading the app's JWT access tokens (HS256 payload only).
abstract final class JwtAccessToken {
  /// Seconds until the JWT `exp` claim, or null when the token cannot be read.
  ///
  /// Negative when already expired.
  static int? secondsUntilExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final exp = (jsonDecode(payload) as Map<String, dynamic>)['exp'];
      if (exp is! num) return null;
      return exp.toInt() - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return null;
    }
  }

  /// True when [token] is expired or will expire within [bufferSeconds].
  ///
  /// Returns false when expiry cannot be read so callers can fall back to the
  /// server 401 + reactive refresh path.
  static bool needsRefresh(
    String token, {
    int bufferSeconds = 60,
  }) {
    final secondsLeft = secondsUntilExpiry(token);
    if (secondsLeft == null) return false;
    return secondsLeft < bufferSeconds;
  }
}
