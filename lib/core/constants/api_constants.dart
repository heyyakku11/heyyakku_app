abstract final class ApiConstants {
  static const bool isAppLive = false;

  static const String webBaseUrl = 'https://heyyakku-web.vercel.app';
  static const String stagingBaseUrl = 'https://heyyakku-backend.onrender.com';
  static const String liveBasebaseUrl = '';

  static const String baseUrl = isAppLive ? liveBasebaseUrl : stagingBaseUrl;

  static String publicPollUrl(String shareToken) => '$webBaseUrl/p/$shareToken';
}
