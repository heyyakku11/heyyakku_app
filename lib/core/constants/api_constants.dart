abstract final class ApiConstants {
  static const bool isAppLive = false;

  static const String webBaseUrl = 'https://heyyakku-web.vercel.app';
  static const String stagingBaseUrl = 'https://heyyakku-backend.onrender.com';
  static const String liveBasebaseUrl = 'https://heyyakku-backend.onrender.com';

  static const String baseUrl = isAppLive ? liveBasebaseUrl : stagingBaseUrl;

  /// Public privacy policy and terms page on the website.
  static const String policyUrl = '$webBaseUrl/policy';

  /// The link friends open to vote on someone's personality card.
  static String personalityCardUrl(String shareCode) =>
      '$webBaseUrl/personality/$shareCode';

  static String publicPollUrl(String shareCode) =>
      '$webBaseUrl/vote/$shareCode';
}
