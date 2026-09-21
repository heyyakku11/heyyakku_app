abstract final class OtpErrorCodes {
  static const notFound = 'otp_not_found';
  static const invalid = 'otp_invalid';
  static const retryLimitExceeded = 'otp_retry_limit_exceed';

  static String? normalize(String? code) {
    if (code == null) return null;
    final normalized = code.trim().toLowerCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    if (normalized.isEmpty) return null;
    if (normalized == 'otp_retry_limit_exceeded') {
      return retryLimitExceeded;
    }
    return normalized;
  }
}
