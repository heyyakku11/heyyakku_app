import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/payments/payment_confirm_result.dart';
import 'package:yakku/core/payments/payment_error_codes.dart';
import 'package:yakku/core/payments/payment_flow_controller.dart';
import 'package:yakku/core/payments/pending_payment_store.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/payments/razorpay_gateway.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/data/datasources/payment_remote_data_source.dart';
import 'package:yakku/data/models/payments/payment_models.dart';

class _FakePayments implements PaymentRemoteDataSource {
  VerifyPaymentRequest? lastVerify;
  Object? verifyError;
  VerifyPaymentResponse? verifyResponse;
  final List<PaymentOrderStatus> statusQueue = [];
  int getOrderCount = 0;
  int createCount = 0;

  @override
  Future<CreatePaymentOrderResponse> createOrder(
    CreatePaymentOrderRequest request,
  ) {
    createCount += 1;
    throw UnimplementedError('createOrder must not run during confirm/resume');
  }

  @override
  Future<VerifyPaymentResponse> verify(VerifyPaymentRequest request) async {
    lastVerify = request;
    if (verifyError != null) throw verifyError!;
    return verifyResponse ??
        const VerifyPaymentResponse(
          orderId: 'ord-1',
          status: PaymentOrderStatuses.paid,
          alreadyFulfilled: false,
          purchaseType: PaymentPurchaseTypes.userPlan,
          planCode: 'yakku_lite',
        );
  }

  @override
  Future<PaymentOrderStatus> getOrder(String orderId) async {
    getOrderCount += 1;
    if (statusQueue.isEmpty) {
      return PaymentOrderStatus(
        orderId: orderId,
        status: PaymentOrderStatuses.pending,
        purchaseType: PaymentPurchaseTypes.userPlan,
        planCode: 'yakku_lite',
        planName: 'Yakku Lite',
        amountInPaise: 9900,
        currency: 'INR',
        createdAt: DateTime.utc(2026, 11, 19),
        updatedAt: DateTime.utc(2026, 11, 19),
        expiresAt: DateTime.utc(2026, 11, 20),
      );
    }
    return statusQueue.removeAt(0);
  }

  @override
  Future<PaymentHistoryPage> getHistory({int page = 1, int pageSize = 10}) {
    throw UnimplementedError();
  }
}

class _FakeGateway implements RazorpayGateway {
  @override
  void on(String event, Function handler) {}

  @override
  void open(Map<String, dynamic> options) {}

  @override
  void clear() {}
}

PaymentOrderStatus _status({
  required String status,
  String orderId = 'ord-1',
}) {
  return PaymentOrderStatus(
    orderId: orderId,
    status: status,
    purchaseType: PaymentPurchaseTypes.userPlan,
    planCode: 'yakku_lite',
    planName: 'Yakku Lite',
    amountInPaise: 9900,
    currency: 'INR',
    createdAt: DateTime.utc(2026, 11, 19),
    updatedAt: DateTime.utc(2026, 11, 19),
    expiresAt: DateTime.utc(2026, 11, 20),
  );
}

const _success = RazorpayCheckoutSuccess(
  razorpayPaymentId: 'pay_1',
  razorpayOrderId: 'order_ABC',
  razorpaySignature: 'sig_1',
  internalOrderId: 'ord-1',
);

void main() {
  late _FakePayments payments;
  late PendingPaymentStore pending;
  late RazorpayCheckoutService checkout;
  late PaymentFlowController flow;

  setUp(() async {
    payments = _FakePayments();
    pending = PendingPaymentStore(
      secureStorage: SecureStorageService.inMemory(),
    );
    await pending.save(
      PendingPayment(
        orderId: 'ord-1',
        razorpayOrderId: 'order_ABC',
        planCode: 'yakku_lite',
        planName: 'Yakku Lite',
        purchaseType: PaymentPurchaseTypes.userPlan,
        amountInPaise: 9900,
        currency: 'INR',
        savedAt: DateTime.utc(2026, 11, 19),
      ),
    );
    checkout = RazorpayCheckoutService(gateway: _FakeGateway());
    flow = PaymentFlowController(
      payments: payments,
      pendingPayments: pending,
      checkout: checkout,
      sleeper: (_) async {},
      maxPollAttempts: 3,
      pollInterval: Duration.zero,
    );
  });

  tearDown(() {
    flow.dispose();
    checkout.dispose();
  });

  test('confirmCheckoutSuccess verifies and clears pending on Paid', () async {
    final result = await flow.confirmCheckoutSuccess(_success);
    expect(result, isA<PaymentConfirmFulfilled>());
    expect(payments.lastVerify!.razorpayPaymentId, 'pay_1');
    expect(payments.lastVerify!.razorpaySignature, 'sig_1');
    expect(await pending.read(), isNull);
  });

  test('persists verify payload before calling backend', () async {
    payments.verifyError = const ApiException(
      kind: ApiErrorKind.connection,
      message: 'offline',
    );
    payments.statusQueue.addAll([
      _status(status: PaymentOrderStatuses.pending),
      _status(status: PaymentOrderStatuses.pending),
      _status(status: PaymentOrderStatuses.pending),
    ]);

    await flow.confirmCheckoutSuccess(_success);
    // Pending kept with payload for Phase 8 recovery when still not Paid.
    final saved = await pending.read();
    expect(saved, isNotNull);
    expect(saved!.hasVerifyPayload, isTrue);
    expect(saved.razorpayPaymentId, 'pay_1');
  });

  test('polls until Paid when verify returns non-Paid', () async {
    payments.verifyResponse = const VerifyPaymentResponse(
      orderId: 'ord-1',
      status: PaymentOrderStatuses.pending,
      alreadyFulfilled: false,
      purchaseType: PaymentPurchaseTypes.userPlan,
    );
    payments.statusQueue.addAll([
      _status(status: PaymentOrderStatuses.pending),
      _status(status: PaymentOrderStatuses.paid),
    ]);

    final result = await flow.confirmCheckoutSuccess(_success);
    expect(result, isA<PaymentConfirmFulfilled>());
    expect(payments.getOrderCount, 2);
    expect(await pending.read(), isNull);
  });

  test('returns pending after bounded polls', () async {
    payments.verifyResponse = const VerifyPaymentResponse(
      orderId: 'ord-1',
      status: PaymentOrderStatuses.pending,
      alreadyFulfilled: false,
      purchaseType: PaymentPurchaseTypes.userPlan,
    );

    final result = await flow.confirmCheckoutSuccess(_success);
    expect(result, isA<PaymentConfirmPending>());
    expect(payments.getOrderCount, 3);
    expect(await pending.read(), isNotNull);
  });

  test('hard verify failures do not grant access', () async {
    payments.verifyError = const ApiException(
      kind: ApiErrorKind.badRequest,
      message: 'bad sig',
      code: PaymentErrorCodes.paymentSignatureInvalid,
    );

    final result = await flow.confirmCheckoutSuccess(_success);
    expect(result, isA<PaymentConfirmFailed>());
    expect(
      (result as PaymentConfirmFailed).code,
      PaymentErrorCodes.paymentSignatureInvalid,
    );
    expect(payments.getOrderCount, 0);
  });

  test('network timeout after checkout keeps pending and does not grant',
      () async {
    payments.verifyError = const ApiException(
      kind: ApiErrorKind.timeout,
      message: 'timed out',
    );

    final result = await flow.confirmCheckoutSuccess(_success);
    expect(result, isA<PaymentConfirmPending>());
    expect(payments.createCount, 0);
    final saved = await pending.read();
    expect(saved, isNotNull);
    expect(saved!.hasVerifyPayload, isTrue);
  });

  test('app-restart reconcile retries verify without creating a new order',
      () async {
    await pending.save(
      (await pending.read())!.copyWith(
        razorpayPaymentId: 'pay_1',
        razorpaySignature: 'sig_1',
      ),
    );

    final result = await flow.reconcilePendingPayment();
    expect(result, isA<PaymentConfirmFulfilled>());
    expect(payments.createCount, 0);
    expect(payments.lastVerify!.razorpayPaymentId, 'pay_1');
    expect(await pending.read(), isNull);
  });

  test('refreshOrderStatus can settle a pending order without new payment',
      () async {
    payments.statusQueue.add(_status(status: PaymentOrderStatuses.paid));
    final result = await flow.refreshOrderStatus('ord-1');
    expect(result, isA<PaymentConfirmFulfilled>());
    expect(await pending.read(), isNull);
  });

  test('reconcilePendingPayment retries verify when payload exists', () async {
    await pending.save(
      (await pending.read())!.copyWith(
        razorpayPaymentId: 'pay_1',
        razorpaySignature: 'sig_1',
      ),
    );

    final result = await flow.reconcilePendingPayment();
    expect(result, isA<PaymentConfirmFulfilled>());
    expect(payments.lastVerify!.razorpayPaymentId, 'pay_1');
    expect(await pending.read(), isNull);
  });

  test('reconcilePendingPayment polls status without verify payload', () async {
    payments.statusQueue.add(_status(status: PaymentOrderStatuses.paid));
    final result = await flow.reconcilePendingPayment();
    expect(result, isA<PaymentConfirmFulfilled>());
    expect(payments.lastVerify, isNull);
    expect(payments.getOrderCount, 1);
  });

  test('reconcilePendingPayment returns null when nothing pending', () async {
    await pending.clear();
    expect(await flow.reconcilePendingPayment(), isNull);
  });

  test('reconcileAfterCheckoutClosed finds Paid after cancel', () async {
    payments.statusQueue.add(_status(status: PaymentOrderStatuses.paid));
    final result = await flow.reconcileAfterCheckoutClosed(orderId: 'ord-1');
    expect(result, isA<PaymentConfirmFulfilled>());
    expect(await pending.read(), isNull);
  });
}
