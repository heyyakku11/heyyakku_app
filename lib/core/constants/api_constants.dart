abstract final class ApiConstants {
  /// Build with `--dart-define=ENV=dev|staging|production` (matches Android flavors).
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static String get backendBaseUrl {
    switch (environment) {
      case 'dev':
        return 'https://heyyakku-backend.onrender.com';

      case 'staging':
        return 'https://backend-stage-l0yc.onrender.com';

      case 'production':
        return '';

      default:
        throw UnsupportedError(
          'Unknown environment: $environment. Use ENV=dev|staging|production.',
        );
    }
  }

  static String get webBaseUrl {
    switch (environment) {
      case 'dev':
        return 'https://heyyakku-web-git-develop-heyyakku33-9072.vercel.app';

      case 'staging':
        return 'https://heyyakku-web-git-staging-heyyakku33-9072.vercel.app';

      case 'production':
        return '';

      default:
        throw UnsupportedError(
          'Unknown environment: $environment. Use ENV=dev|staging|production.',
        );
    }
  }

  /// Where "Email to" and "Report a problem" in settings send mail. Empty until
  /// the real support address is set; the rows then explain that.
  static const String supportEmail = 'contact@heyyakku.com';

  /// Public privacy policy and terms page on the website.
  static String get policyUrl => '$webBaseUrl/policy';

  /// Public terms of service page on the website.
  static String get termsUrl => '$webBaseUrl/terms';

  /// The link friends open to vote on someone's personality card.
  static String personalityCardUrl(String shareCode) =>
      '$webBaseUrl/personality/$shareCode';

  static String publicPollUrl(String shareCode) =>
      '$webBaseUrl/vote/$shareCode';
}
