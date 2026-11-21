import 'package:yakku/core/payments/payment_confirm_result.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/payments/razorpay_gateway.dart';

/// Short UI copy for Checkout / verify outcomes.
abstract final class CheckoutUserMessages {
  /// Null when the UI should stay silent (user cancelled).
  ///
  /// Checkout success alone is not shown as paid — verify handles that.
  static String? forCheckoutResult(RazorpayCheckoutResult result) {
    return switch (result) {
      RazorpayCheckoutSuccess() => null,
      RazorpayCheckoutFailure(:final isCancelled, :final code, :final message) =>
        isCancelled
            ? null
            : _failureMessage(code: code, sdkMessage: message),
    };
  }

  /// Null when the caller should stay silent.
  ///
  /// Set [notifyPending] false for background reconcile / cancel checks so
  /// "still processing" does not spam the user.
  static String? forConfirmResult(
    PaymentConfirmResult result, {
    bool notifyPending = true,
  }) {
    return switch (result) {
      PaymentConfirmFulfilled(:final alreadyFulfilled) => alreadyFulfilled
          ? 'You already have this purchase.'
          : 'Payment successful.',
      PaymentConfirmPending(:final message) =>
        notifyPending ? message : null,
      PaymentConfirmFailed(:final message) => message,
    };
  }

  static String forOpenFailure(Object error) {
    if (error is RazorpayCheckoutException) return error.message;
    return 'Could not open payment checkout. Please try again.';
  }

  static String _failureMessage({
    required int? code,
    required String sdkMessage,
  }) {
    if (code == RazorpayGatewayErrorCodes.networkError) {
      return 'Network error during payment. Check your connection and try again.';
    }
    if (code == RazorpayGatewayErrorCodes.invalidOptions) {
      return 'Payment could not be started. Please try again.';
    }
    final trimmed = sdkMessage.trim();
    if (trimmed.isNotEmpty &&
        trimmed.toLowerCase() != 'undefined' &&
        trimmed.toLowerCase() != 'null') {
      return trimmed;
    }
    return 'Payment failed. Please try again.';
  }
}
