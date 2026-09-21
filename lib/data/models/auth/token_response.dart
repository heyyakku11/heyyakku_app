class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
  final int refreshTokenExpiresInSeconds;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      accessTokenExpiresInSeconds:
          json['accessTokenExpiresInSeconds'] as int? ?? 0,
      refreshTokenExpiresInSeconds:
          json['refreshTokenExpiresInSeconds'] as int? ?? 0,
    );
  }
}
