class VerifyOtpData {
  final String userId;
  final String name;
  final String anonymousName;
  final String purpose;
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresInSeconds;
  final int refreshTokenExpiresInSeconds;

  const VerifyOtpData({
    required this.userId,
    required this.name,
    required this.anonymousName,
    required this.purpose,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresInSeconds,
    required this.refreshTokenExpiresInSeconds,
  });

  factory VerifyOtpData.fromJson(Map<String, dynamic> json) {
    return VerifyOtpData(
      userId: json['userId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      anonymousName: json['anonymousName'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      accessTokenExpiresInSeconds:
          json['accessTokenExpiresInSeconds'] as int? ?? 0,
      refreshTokenExpiresInSeconds:
          json['refreshTokenExpiresInSeconds'] as int? ?? 0,
    );
  }
}
