/// Backend payment / purchase error codes from `ApiErrorCodes`.
///
/// Compare against [ApiException.code] after [DioErrorMapper.map].
abstract final class PaymentErrorCodes {
  static const planAlreadyActive = 'PLAN_ALREADY_ACTIVE';
  static const planDowngradeNotAllowed = 'PLAN_DOWNGRADE_NOT_ALLOWED';
  static const cardAlreadyUnlocked = 'CARD_ALREADY_UNLOCKED';
  static const paymentProviderDisabled = 'PAYMENT_PROVIDER_DISABLED';
  static const paymentGatewayError = 'PAYMENT_GATEWAY_ERROR';
  static const paymentSignatureInvalid = 'PAYMENT_SIGNATURE_INVALID';
  static const paymentNotCaptured = 'PAYMENT_NOT_CAPTURED';
  static const paymentOrderMismatch = 'PAYMENT_ORDER_MISMATCH';
  static const paymentAmountMismatch = 'PAYMENT_AMOUNT_MISMATCH';
  static const paymentCurrencyMismatch = 'PAYMENT_CURRENCY_MISMATCH';
  static const unauthorized = 'UNAUTHORIZED';
  static const validationError = 'VALIDATION_ERROR';
  static const notFound = 'NOT_FOUND';
  static const conflict = 'CONFLICT';

  /// True when the backend rejected the purchase for a business rule (not a
  /// transient network/gateway failure).
  static bool isPurchaseRejected(String? code) {
    return switch (code) {
      planAlreadyActive ||
      planDowngradeNotAllowed ||
      cardAlreadyUnlocked ||
      validationError ||
      notFound => true,
      _ => false,
    };
  }

  /// Short UI copy for known payment codes; null when the caller should use
  /// the server message or a generic fallback.
  static String? userMessage(String? code) {
    return switch (code) {
      planAlreadyActive => 'You already have this plan.',
      planDowngradeNotAllowed =>
        'You already have Yakku Love. Downgrading to Lite is not allowed.',
      cardAlreadyUnlocked => 'This card is already unlocked permanently.',
      paymentProviderDisabled =>
        'Payments are temporarily unavailable. Please try again later.',
      paymentGatewayError =>
        'Could not start checkout with the payment provider. Try again.',
      paymentSignatureInvalid =>
        'Payment could not be verified. Contact support if you were charged.',
      paymentNotCaptured =>
        'Payment is not confirmed yet. You can check the status again.',
      paymentOrderMismatch ||
      paymentAmountMismatch ||
      paymentCurrencyMismatch =>
        'Payment details did not match. Contact support if you were charged.',
      unauthorized => 'Please sign in again to continue.',
      _ => null,
    };
  }
}
