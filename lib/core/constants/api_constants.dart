abstract final class ApiConstants {
  //development, staging, production
  static const String environment = "development";

  static String get backendBaseUrl {
    switch (environment) {
      case 'development':
        return 'https://heyyakku-backend.onrender.com';

      case 'staging':
        return 'https://backend-stage-l0yc.onrender.com';

      case 'production':
        return '';

      default:
        throw UnsupportedError(
          'Unknown environment: $environment',
        );
    }
  }

  static String get webBaseUrl {
    switch (environment) {
      case 'development':
        return 'https://heyyakku-web-git-develop-heyyakku33-9072.vercel.app/';

      case 'staging':
        return 'https://heyyakku-web-git-staging-heyyakku33-9072.vercel.app/';

      case 'production':
        return '';

      default:
        throw UnsupportedError(
          'Unknown environment: $environment',
        );
    }
  }

  /// Where "Email to" and "Report a problem" in settings send mail. Empty until
  /// the real support address is set; the rows then explain that.
  static const String supportEmail = 'contact@heyyakku.com';

  /// Public privacy policy and terms page on the website.
  static  String policyUrl = '$webBaseUrl/policy';

  /// Public terms of service page on the website.
  static  String termsUrl = '$webBaseUrl/terms';

  /// The link friends open to vote on someone's personality card.
  static String personalityCardUrl(String shareCode) =>
      '$webBaseUrl/personality/$shareCode';

  static String publicPollUrl(String shareCode) =>
      '$webBaseUrl/vote/$shareCode';
}
