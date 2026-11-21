import 'package:flutter/foundation.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/payments/checkout_prefill.dart';
import 'package:yakku/core/payments/payment_confirm_result.dart';
import 'package:yakku/core/payments/payment_error_codes.dart';
import 'package:yakku/core/payments/pending_payment_store.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/payments/razorpay_gateway.dart';
import 'package:yakku/data/datasources/payment_remote_data_source.dart';
import 'package:yakku/data/models/payments/payment_models.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';

/// Delay used between order-status polls. Injectable for tests.
typedef PaymentPollSleeper = Future<void> Function(Duration delay);

/// Outcome of creating a payment order (before / without Checkout).
sealed class PaymentOrderStartResult {
  const PaymentOrderStartResult();
}

class PaymentOrderStartSuccess extends PaymentOrderStartResult {
  const PaymentOrderStartSuccess(this.order);

  final CreatePaymentOrderResponse order;
}

class PaymentOrderStartFailure extends PaymentOrderStartResult {
  const PaymentOrderStartFailure({
    required this.message,
    this.code,
    this.isBusy = false,
  });

  final String message;
  final String? code;
  final bool isBusy;
}

/// Creates backend payment orders, opens Razorpay Checkout, and confirms
/// fulfillment via backend verify + bounded status polling.
///
/// Entitlement is never granted locally — only after the backend reports Paid.
class PaymentFlowController extends ChangeNotifier {
  PaymentFlowController({
    required this._payments,
    required this._pendingPayments,
    required this._checkout,
    PaymentPollSleeper? sleeper,
    this.maxPollAttempts = 5,
    this.pollInterval = const Duration(seconds: 1),
  }) : _sleep = sleeper ?? Future<void>.delayed;

  final PaymentRemoteDataSource _payments;
  final PendingPaymentStore _pendingPayments;
  final RazorpayCheckoutService _checkout;
  final PaymentPollSleeper _sleep;

  /// How many `GET .../orders/{id}` polls after verify returns non-Paid.
  final int maxPollAttempts;
  final Duration pollInterval;

  bool _busy = false;
  bool _confirming = false;
  String? _inFlightIdempotencyKey;

  bool get isBusy =>
      _busy ||
      _confirming ||
      _checkout.isSessionActive ||
      _checkout.isOpening;

  bool get isConfirming => _confirming;

  /// Creates a backend payment order. Does not open Checkout.
  ///
  /// On success, persists a [PendingPayment] recovery record. Does not grant
  /// entitlements. Uses one idempotency key for the in-flight attempt.
  Future<PaymentOrderStartResult> createOrder({
    required YakkuPlan plan,
    String? contentType,
    String? contentId,
  }) async {
    if (_busy || _checkout.isSessionActive || _checkout.isOpening) {
      return const PaymentOrderStartFailure(
        message: 'A payment is already in progress.',
        isBusy: true,
      );
    }

    if (plan.isThisCard) {
      if (contentType == null ||
          contentType.isEmpty ||
          contentId == null ||
          contentId.isEmpty) {
        return const PaymentOrderStartFailure(
          message: 'This card purchase needs the card context.',
          code: PaymentErrorCodes.validationError,
        );
      }
    }

    _busy = true;
    _inFlightIdempotencyKey ??= newPaymentIdempotencyKey();
    notifyListeners();

    try {
      final order = await _payments.createOrder(
        CreatePaymentOrderRequest(
          planId: plan.id,
          idempotencyKey: _inFlightIdempotencyKey!,
          contentType: plan.isThisCard ? contentType : null,
          contentId: plan.isThisCard ? contentId : null,
        ),
      );

      if (order.razorpayOrderId.isEmpty ||
          order.razorpayKeyId.isEmpty ||
          order.amountInPaise <= 0) {
        return const PaymentOrderStartFailure(
          message: 'Could not start checkout. Please try again.',
          code: PaymentErrorCodes.paymentGatewayError,
        );
      }

      try {
        await _pendingPayments.save(
          PendingPayment(
            orderId: order.orderId,
            razorpayOrderId: order.razorpayOrderId,
            planCode: order.planCode,
            planName: order.planName,
            purchaseType: order.purchaseType,
            amountInPaise: order.amountInPaise,
            currency: order.currency,
            savedAt: DateTime.now().toUtc(),
            contentType: order.contentType,
            contentId: order.contentId,
          ),
        );
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint(
            '[Payments] pending payment save failed: $error\n$stack',
          );
        }
        // Backend order exists; continue so Checkout can still open.
      }

      return PaymentOrderStartSuccess(order);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[Payments] createOrder failed: $error\n$stack');
      }
      final mapped = DioErrorMapper.map(
        error,
        fallback: 'Could not create payment order. Please try again.',
      );
      return PaymentOrderStartFailure(
        message: PaymentErrorCodes.userMessage(mapped.code) ?? mapped.message,
        code: mapped.code,
      );
    } finally {
      _busy = false;
      _inFlightIdempotencyKey = null;
      notifyListeners();
    }
  }

  /// Opens Razorpay Checkout for a backend-created order.
  ///
  /// Prefill contact/email are normalized. Returns a [RazorpayCheckoutFailure]
  /// instead of throwing when the SDK cannot be opened.
  Future<RazorpayCheckoutResult> openCheckout(
    CreatePaymentOrderResponse order, {
    String? contact,
    String? email,
  }) async {
    if (_busy) {
      return RazorpayCheckoutFailure(
        code: RazorpayGatewayErrorCodes.unknownError,
        message: 'A payment is already in progress.',
        isCancelled: false,
        internalOrderId: order.orderId,
      );
    }
    try {
      return await _checkout.open(
        RazorpayCheckoutOptions.fromOrder(
          order,
          contact: CheckoutPrefill.contact(contact),
          email: CheckoutPrefill.email(email),
        ),
      );
    } on RazorpayCheckoutException catch (error) {
      return RazorpayCheckoutFailure(
        code: RazorpayGatewayErrorCodes.unknownError,
        message: error.message,
        isCancelled: false,
        internalOrderId: order.orderId,
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[Payments] openCheckout failed: $error\n$stack');
      }
      return RazorpayCheckoutFailure(
        code: RazorpayGatewayErrorCodes.unknownError,
        message: 'Could not open payment checkout. Please try again.',
        isCancelled: false,
        internalOrderId: order.orderId,
      );
    }
  }

  /// Create order then open Checkout.
  Future<({PaymentOrderStartResult start, RazorpayCheckoutResult? checkout})>
  startPurchase({
    required YakkuPlan plan,
    String? contentType,
    String? contentId,
    String? contact,
    String? email,
  }) async {
    final started = await createOrder(
      plan: plan,
      contentType: contentType,
      contentId: contentId,
    );
    if (started is! PaymentOrderStartSuccess) {
      return (start: started, checkout: null);
    }
    final result = await openCheckout(
      started.order,
      contact: contact,
      email: email,
    );
    return (start: started, checkout: result);
  }

  /// Persists the Checkout success payload, calls backend verify, and polls
  /// order status when fulfillment is still pending.
  ///
  /// Never grants entitlement itself — callers refresh from backend APIs after
  /// [PaymentConfirmFulfilled].
  Future<PaymentConfirmResult> confirmCheckoutSuccess(
    RazorpayCheckoutSuccess success,
  ) async {
    if (_confirming) {
      return PaymentConfirmFailed(
        message: 'Payment confirmation is already in progress.',
        orderId: success.internalOrderId,
      );
    }

    _confirming = true;
    notifyListeners();

    try {
      await _persistVerifyPayload(success);

      final orderId = success.internalOrderId;
      try {
        final verify = await _payments.verify(
          VerifyPaymentRequest(
            razorpayOrderId: success.razorpayOrderId,
            razorpayPaymentId: success.razorpayPaymentId,
            razorpaySignature: success.razorpaySignature,
          ),
        );

        if (verify.isPaid) {
          await _pendingPayments.clearIfOrder(
            verify.orderId.isNotEmpty
                ? verify.orderId
                : (orderId ?? ''),
          );
          if (orderId != null &&
              orderId.isNotEmpty &&
              verify.orderId.isNotEmpty &&
              orderId != verify.orderId) {
            await _pendingPayments.clearIfOrder(orderId);
          }
          return PaymentConfirmFulfilled.fromVerify(verify);
        }

        final pollOrderId =
            verify.orderId.isNotEmpty ? verify.orderId : orderId;
        if (pollOrderId == null || pollOrderId.isEmpty) {
          return const PaymentConfirmPending(
            orderId: '',
          );
        }
        return await _pollUntilSettled(pollOrderId);
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint('[Payments] verify failed: $error\n$stack');
        }
        final mapped = DioErrorMapper.map(
          error,
          fallback: 'Could not verify payment. Please try again.',
        );

        if (_isHardVerifyFailure(mapped)) {
          return PaymentConfirmFailed(
            message:
                PaymentErrorCodes.userMessage(mapped.code) ?? mapped.message,
            code: mapped.code,
            orderId: orderId,
          );
        }

        // Network / not-captured / still processing → poll when we have an id.
        if (orderId != null && orderId.isNotEmpty) {
          return await _pollUntilSettled(orderId);
        }

        return PaymentConfirmPending(
          orderId: orderId ?? '',
          message: PaymentErrorCodes.userMessage(mapped.code) ??
              'Your payment is being processed. You can check the payment status again.',
        );
      }
    } finally {
      _confirming = false;
      notifyListeners();
    }
  }

  /// Re-check a pending order without creating a new payment.
  Future<PaymentConfirmResult> refreshOrderStatus(String orderId) async {
    if (orderId.isEmpty) {
      return const PaymentConfirmFailed(message: 'Missing payment order.');
    }
    if (_confirming) {
      return PaymentConfirmFailed(
        message: 'Payment confirmation is already in progress.',
        orderId: orderId,
      );
    }
    _confirming = true;
    notifyListeners();
    try {
      return await _pollUntilSettled(orderId, attempts: maxPollAttempts);
    } finally {
      _confirming = false;
      notifyListeners();
    }
  }

  /// Recovers a locally stored pending payment without creating a new order.
  ///
  /// - If a verify payload exists, retries `POST /verify` then polls status.
  /// - Otherwise polls `GET .../orders/{id}` only.
  ///
  /// Returns null when nothing is pending. Never grants entitlement locally.
  Future<PaymentConfirmResult?> reconcilePendingPayment({
    int? pollAttempts,
  }) async {
    final pending = await _pendingPayments.read();
    if (pending == null || pending.orderId.isEmpty) return null;

    if (_confirming || _busy || _checkout.isSessionActive || _checkout.isOpening) {
      return PaymentConfirmPending(orderId: pending.orderId);
    }

    _confirming = true;
    notifyListeners();
    try {
      if (pending.hasVerifyPayload) {
        return await _retryVerifyThenPoll(
          pending,
          pollAttempts: pollAttempts,
        );
      }
      return await _pollUntilSettled(
        pending.orderId,
        attempts: pollAttempts ?? maxPollAttempts,
      );
    } finally {
      _confirming = false;
      notifyListeners();
    }
  }

  /// After Checkout closes (cancel / SDK error), query backend status in case
  /// capture already happened. Does not create a new order.
  Future<PaymentConfirmResult> reconcileAfterCheckoutClosed({
    required String orderId,
    int pollAttempts = 3,
  }) async {
    if (orderId.isEmpty) {
      return const PaymentConfirmFailed(message: 'Missing payment order.');
    }
    if (_confirming) {
      return PaymentConfirmFailed(
        message: 'Payment confirmation is already in progress.',
        orderId: orderId,
      );
    }

    _confirming = true;
    notifyListeners();
    try {
      final pending = await _pendingPayments.read();
      if (pending != null &&
          pending.orderId == orderId &&
          pending.hasVerifyPayload) {
        return await _retryVerifyThenPoll(
          pending,
          pollAttempts: pollAttempts,
        );
      }
      return await _pollUntilSettled(orderId, attempts: pollAttempts);
    } finally {
      _confirming = false;
      notifyListeners();
    }
  }

  Future<PaymentConfirmResult> _retryVerifyThenPoll(
    PendingPayment pending, {
    int? pollAttempts,
  }) async {
    try {
      final verify = await _payments.verify(
        VerifyPaymentRequest(
          razorpayOrderId: pending.razorpayOrderId,
          razorpayPaymentId: pending.razorpayPaymentId!,
          razorpaySignature: pending.razorpaySignature!,
        ),
      );
      if (verify.isPaid) {
        await _pendingPayments.clearIfOrder(pending.orderId);
        if (verify.orderId.isNotEmpty && verify.orderId != pending.orderId) {
          await _pendingPayments.clearIfOrder(verify.orderId);
        }
        return PaymentConfirmFulfilled.fromVerify(verify);
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[Payments] reconcile verify failed: $error\n$stack');
      }
      final mapped = DioErrorMapper.map(
        error,
        fallback: 'Could not verify payment. Please try again.',
      );
      if (_isHardVerifyFailure(mapped)) {
        // Keep pending for support; do not invent a new order.
        return PaymentConfirmFailed(
          message:
              PaymentErrorCodes.userMessage(mapped.code) ?? mapped.message,
          code: mapped.code,
          orderId: pending.orderId,
        );
      }
    }

    return await _pollUntilSettled(
      pending.orderId,
      attempts: pollAttempts ?? maxPollAttempts,
    );
  }

  Future<void> _persistVerifyPayload(RazorpayCheckoutSuccess success) async {
    try {
      final current = await _pendingPayments.read();
      if (current != null &&
          ((success.internalOrderId != null &&
                  success.internalOrderId!.isNotEmpty &&
                  current.orderId == success.internalOrderId) ||
              current.razorpayOrderId == success.razorpayOrderId)) {
        await _pendingPayments.save(
          current.copyWith(
            razorpayPaymentId: success.razorpayPaymentId,
            razorpaySignature: success.razorpaySignature,
          ),
        );
        return;
      }

      if (success.internalOrderId == null || success.internalOrderId!.isEmpty) {
        return;
      }

      await _pendingPayments.save(
        PendingPayment(
          orderId: success.internalOrderId!,
          razorpayOrderId: success.razorpayOrderId,
          planCode: current?.planCode ?? '',
          planName: current?.planName ?? '',
          purchaseType: current?.purchaseType ?? '',
          amountInPaise: current?.amountInPaise ?? 0,
          currency: current?.currency ?? 'INR',
          savedAt: DateTime.now().toUtc(),
          contentType: current?.contentType,
          contentId: current?.contentId,
          razorpayPaymentId: success.razorpayPaymentId,
          razorpaySignature: success.razorpaySignature,
        ),
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint(
          '[Payments] persist verify payload failed: $error\n$stack',
        );
      }
    }
  }

  Future<PaymentConfirmResult> _pollUntilSettled(
    String orderId, {
    int? attempts,
  }) async {
    final maxAttempts = attempts ?? maxPollAttempts;
    for (var i = 0; i < maxAttempts; i++) {
      if (i > 0) await _sleep(pollInterval);
      try {
        final status = await _payments.getOrder(orderId);
        if (status.isPaid) {
          await _pendingPayments.clearIfOrder(orderId);
          return PaymentConfirmFulfilled.fromStatus(status);
        }
        if (status.isTerminal) {
          await _pendingPayments.clearIfOrder(orderId);
          return PaymentConfirmFailed(
            message: 'Payment was not completed.',
            orderId: orderId,
          );
        }
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint('[Payments] poll order failed: $error\n$stack');
        }
        // Keep polling on transient errors.
      }
    }

    return PaymentConfirmPending(orderId: orderId);
  }

  bool _isHardVerifyFailure(ApiException error) {
    return switch (error.code) {
      PaymentErrorCodes.paymentSignatureInvalid ||
      PaymentErrorCodes.paymentOrderMismatch ||
      PaymentErrorCodes.paymentAmountMismatch ||
      PaymentErrorCodes.paymentCurrencyMismatch ||
      PaymentErrorCodes.unauthorized ||
      PaymentErrorCodes.validationError ||
      PaymentErrorCodes.notFound => true,
      _ => error.kind == ApiErrorKind.unauthorized ||
          error.kind == ApiErrorKind.forbidden ||
          error.kind == ApiErrorKind.badRequest ||
          error.kind == ApiErrorKind.validation,
    };
  }
}
