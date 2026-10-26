/// `data` of `POST /api/v1/auth/verify`:
///
/// ```json
/// {
///   "purpose": "Registration",
///   "accountRestored": false,
///   "user": { "name": "...", "anonymousName": "...", "isPushAllowed": true },
///   "auth": { "accessToken": "...", "refreshToken": "...", ... }
/// }
/// ```
class VerifyOtpData {
  final String purpose;

  /// True when this login cancelled a pending account deletion.
  final bool accountRestored;
  final VerifyOtpUser user;
  final VerifyOtpAuth auth;

  const VerifyOtpData({
    required this.purpose,
    required this.accountRestored,
    required this.user,
    required this.auth,
  });

  factory VerifyOtpData.fromJson(Map<String, dynamic> json) {
    return VerifyOtpData(
      purpose: json['purpose'] as String? ?? '',
      accountRestored: json['accountRestored'] as bool? ?? false,
      user: VerifyOtpUser.fromJson(_asMap(json['user'])),
      auth: VerifyOtpAuth.fromJson(_asMap(json['auth'])),
    );
  }
}

class VerifyOtpUser {
  final String name;
  final String anonymousName;

  /// Whether the account allows push notifications (the in-app switch, on by
  /// default). Not the phone's OS permission; that is reported through
  /// `PATCH /devices/me`.
  final bool isPushAllowed;

  const VerifyOtpUser({
    required this.name,
    required this.anonymousName,
    required this.isPushAllowed,
  });

  factory VerifyOtpUser.fromJson(Map<String, dynamic> json) {
    return VerifyOtpUser(
      name: json['name'] as String? ?? '',
      anonymousName: json['anonymousName'] as String? ?? '',
      isPushAllowed: json['isPushAllowed'] as bool? ?? true,
    );
  }
}

class VerifyOtpAuth {
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
  final int refreshTokenExpiresInSeconds;

  const VerifyOtpAuth({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
  });

  factory VerifyOtpAuth.fromJson(Map<String, dynamic> json) {
    return VerifyOtpAuth(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      accessTokenExpiresInSeconds:
          json['accessTokenExpiresInSeconds'] as int? ?? 0,
      refreshTokenExpiresInSeconds:
          json['refreshTokenExpiresInSeconds'] as int? ?? 0,
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  return value is Map<String, dynamic> ? value : const <String, dynamic>{};
}
