import 'package:yakku/data/models/payments/payment_models.dart';

/// Outcome of backend verification / status polling after Checkout success.
///
/// Entitlement is only confirmed when [PaymentConfirmFulfilled] is returned.
sealed class PaymentConfirmResult {
  const PaymentConfirmResult();
}

/// Backend reports the order as Paid (including already-fulfilled retries).
class PaymentConfirmFulfilled extends PaymentConfirmResult {
  const PaymentConfirmFulfilled({
    required this.orderId,
    required this.purchaseType,
    this.planCode,
    this.planExpiresAt,
    this.contentType,
    this.contentId,
    this.alreadyFulfilled = false,
  });

  factory PaymentConfirmFulfilled.fromVerify(VerifyPaymentResponse verify) {
    return PaymentConfirmFulfilled(
      orderId: verify.orderId,
      purchaseType: verify.purchaseType,
      planCode: verify.planCode,
      planExpiresAt: verify.planExpiresAt,
      contentType: verify.contentType,
      contentId: verify.contentId,
      alreadyFulfilled: verify.alreadyFulfilled,
    );
  }

  factory PaymentConfirmFulfilled.fromStatus(PaymentOrderStatus status) {
    return PaymentConfirmFulfilled(
      orderId: status.orderId,
      purchaseType: status.purchaseType,
      planCode: status.planCode,
      contentType: status.contentType,
      contentId: status.contentId,
    );
  }

  final String orderId;
  final String purchaseType;
  final String? planCode;
  final DateTime? planExpiresAt;
  final String? contentType;
  final String? contentId;
  final bool alreadyFulfilled;
}

/// Capture/fulfillment still in progress after bounded polling.
class PaymentConfirmPending extends PaymentConfirmResult {
  const PaymentConfirmPending({
    required this.orderId,
    this.message =
        'Your payment is being processed. You can check the payment status again.',
  });

  final String orderId;
  final String message;
}

/// Verification rejected or order ended without Paid.
class PaymentConfirmFailed extends PaymentConfirmResult {
  const PaymentConfirmFailed({
    required this.message,
    this.code,
    this.orderId,
  });

  final String message;
  final String? code;
  final String? orderId;
}
