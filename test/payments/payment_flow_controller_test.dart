import 'package:flutter_test/flutter_test.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/payments/payment_error_codes.dart';
import 'package:yakku/core/payments/payment_flow_controller.dart';
import 'package:yakku/core/payments/pending_payment_store.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/payments/razorpay_gateway.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/data/datasources/payment_remote_data_source.dart';
import 'package:yakku/data/models/payments/payment_models.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';

class _FakePayments implements PaymentRemoteDataSource {
  CreatePaymentOrderRequest? lastRequest;
  Object? error;
  CreatePaymentOrderResponse? response;
  int createCount = 0;
  Duration delay = Duration.zero;

  @override
  Future<CreatePaymentOrderResponse> createOrder(
    CreatePaymentOrderRequest request,
  ) async {
    createCount += 1;
    lastRequest = request;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return response ??
        CreatePaymentOrderResponse(
          orderId: 'ord-1',
          razorpayOrderId: 'order_ABC',
          razorpayKeyId: 'rzp_test_123',
          amountInPaise: 9900,
          currency: 'INR',
          purchaseType: PaymentPurchaseTypes.userPlan,
          planCode: YakkuPlan.liteCode,
          planName: 'Yakku Lite',
          status: PaymentOrderStatuses.created,
          expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
        );
  }

  @override
  Future<PaymentOrderStatus> getOrder(String orderId) {
    throw UnimplementedError();
  }

  @override
  Future<PaymentHistoryPage> getHistory({int page = 1, int pageSize = 10}) {
    throw UnimplementedError();
  }

  @override
  Future<VerifyPaymentResponse> verify(VerifyPaymentRequest request) {
    throw UnimplementedError();
  }
}

class _FakeGateway implements RazorpayGateway {
  final Map<String, Function> handlers = {};
  int openCount = 0;
  Map<String, dynamic>? lastOptions;
  Object? openError;

  @override
  void on(String event, Function handler) {
    handlers[event] = handler;
  }

  @override
  void open(Map<String, dynamic> options) {
    openCount += 1;
    lastOptions = options;
    if (openError != null) throw openError!;
  }

  @override
  void clear() {
    handlers.clear();
  }

  void emitCancelled() {
    handlers[RazorpayGatewayEvents.paymentError]?.call(
      PaymentFailureResponse(
        RazorpayGatewayErrorCodes.paymentCancelled,
        'Payment cancelled by user',
        null,
      ),
    );
  }
}

const _lite = YakkuPlan(
  id: 'plan-lite',
  code: YakkuPlan.liteCode,
  name: 'Yakku Lite',
  priceMinor: 9900,
  currency: 'INR',
  durationDays: 7,
  unlockTickets: 3,
  askBackMessageLimit: 3,
);

const _thisCard = YakkuPlan(
  id: 'plan-card',
  code: YakkuPlan.thisCardCode,
  name: 'This card',
  priceMinor: 4900,
  currency: 'INR',
  askBackMessageLimit: 1,
);

void main() {
  late _FakePayments payments;
  late PendingPaymentStore pending;
  late _FakeGateway gateway;
  late RazorpayCheckoutService checkout;
  late PaymentFlowController flow;

  setUp(() {
    payments = _FakePayments();
    pending = PendingPaymentStore(
      secureStorage: SecureStorageService.inMemory(),
    );
    gateway = _FakeGateway();
    checkout = RazorpayCheckoutService(gateway: gateway);
    flow = PaymentFlowController(
      payments: payments,
      pendingPayments: pending,
      checkout: checkout,
    );
  });

  tearDown(() {
    flow.dispose();
    checkout.dispose();
  });

  test('createOrder posts planId + idempotency and saves pending payment',
      () async {
    final result = await flow.createOrder(plan: _lite);
    expect(result, isA<PaymentOrderStartSuccess>());
    expect(payments.createCount, 1);
    expect(payments.lastRequest!.planId, 'plan-lite');
    expect(payments.lastRequest!.idempotencyKey, isNotEmpty);
    expect(payments.lastRequest!.contentType, isNull);

    final saved = await pending.read();
    expect(saved, isNotNull);
    expect(saved!.orderId, 'ord-1');
    expect(saved.razorpayOrderId, 'order_ABC');
    expect(saved.planCode, YakkuPlan.liteCode);
  });

  test('this_card requires content context', () async {
    final missing = await flow.createOrder(plan: _thisCard);
    expect(missing, isA<PaymentOrderStartFailure>());
    expect(
      (missing as PaymentOrderStartFailure).code,
      PaymentErrorCodes.validationError,
    );
    expect(payments.createCount, 0);

    final ok = await flow.createOrder(
      plan: _thisCard,
      contentType: 'poll',
      contentId: 'poll-1',
    );
    expect(ok, isA<PaymentOrderStartSuccess>());
    expect(payments.lastRequest!.contentType, 'poll');
    expect(payments.lastRequest!.contentId, 'poll-1');
  });

  test('maps business error codes to user messages', () async {
    payments.error = const ApiException(
      kind: ApiErrorKind.conflict,
      message: 'Already active',
      code: PaymentErrorCodes.planAlreadyActive,
    );
    final result = await flow.createOrder(plan: _lite);
    expect(result, isA<PaymentOrderStartFailure>());
    final failure = result as PaymentOrderStartFailure;
    expect(failure.code, PaymentErrorCodes.planAlreadyActive);
    expect(failure.message, 'You already have this plan.');
    expect(await pending.read(), isNull);
  });

  test('maps downgrade, unlocked card, and provider-disabled errors', () async {
    Future<PaymentOrderStartFailure> failWith({
      required String code,
      required ApiErrorKind kind,
      String message = 'rejected',
    }) async {
      payments.error = ApiException(kind: kind, message: message, code: code);
      final result = await flow.createOrder(plan: _lite);
      expect(result, isA<PaymentOrderStartFailure>());
      expect(await pending.read(), isNull);
      return result as PaymentOrderStartFailure;
    }

    final downgrade = await failWith(
      code: PaymentErrorCodes.planDowngradeNotAllowed,
      kind: ApiErrorKind.conflict,
    );
    expect(downgrade.message, contains('Love'));

    final unlocked = await failWith(
      code: PaymentErrorCodes.cardAlreadyUnlocked,
      kind: ApiErrorKind.conflict,
    );
    expect(unlocked.message, contains('already unlocked'));

    final disabled = await failWith(
      code: PaymentErrorCodes.paymentProviderDisabled,
      kind: ApiErrorKind.server,
    );
    expect(disabled.message, contains('temporarily unavailable'));
  });

  test('maps generic API failure without saving pending', () async {
    payments.error = const ApiException(
      kind: ApiErrorKind.server,
      message: 'boom',
    );
    final result = await flow.createOrder(plan: _lite);
    expect(result, isA<PaymentOrderStartFailure>());
    expect((result as PaymentOrderStartFailure).isBusy, isFalse);
    expect(await pending.read(), isNull);
    expect(payments.createCount, 1);
  });

  test('rejects incomplete gateway payload without opening checkout', () async {
    payments.response = CreatePaymentOrderResponse(
      orderId: 'ord-1',
      razorpayOrderId: '',
      razorpayKeyId: 'rzp_test_123',
      amountInPaise: 9900,
      currency: 'INR',
      purchaseType: PaymentPurchaseTypes.userPlan,
      planCode: YakkuPlan.liteCode,
      planName: 'Yakku Lite',
      status: PaymentOrderStatuses.created,
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
    final result = await flow.createOrder(plan: _lite);
    expect(result, isA<PaymentOrderStartFailure>());
    expect(
      (result as PaymentOrderStartFailure).code,
      PaymentErrorCodes.paymentGatewayError,
    );
  });

  test('single-flight blocks concurrent createOrder', () async {
    payments.delay = const Duration(milliseconds: 80);
    final first = flow.createOrder(plan: _lite);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final second = await flow.createOrder(plan: _lite);
    expect(second, isA<PaymentOrderStartFailure>());
    expect((second as PaymentOrderStartFailure).isBusy, isTrue);
    final firstResult = await first;
    expect(firstResult, isA<PaymentOrderStartSuccess>());
    expect(payments.createCount, 1);
  });

  test('openCheckout launches Razorpay with backend order fields', () async {
    final started =
        await flow.createOrder(plan: _lite) as PaymentOrderStartSuccess;
    final future = flow.openCheckout(started.order, contact: '+91 99999 99999');
    expect(gateway.openCount, 1);
    expect(gateway.lastOptions?['prefill'], {'contact': '9999999999'});
    expect(gateway.lastOptions?['currency'], 'INR');
    expect(gateway.lastOptions?['notes'], {
      'yakku_order_id': 'ord-1',
      'plan_code': YakkuPlan.liteCode,
    });
    gateway.emitCancelled();
    final result = await future;
    expect(result, isA<RazorpayCheckoutFailure>());
    expect((result as RazorpayCheckoutFailure).isCancelled, isTrue);
  });

  test('openCheckout returns failure instead of throwing when SDK open fails',
      () async {
    gateway.openError = Exception('native boom');
    final started =
        await flow.createOrder(plan: _lite) as PaymentOrderStartSuccess;
    final result = await flow.openCheckout(started.order);
    expect(result, isA<RazorpayCheckoutFailure>());
    expect((result as RazorpayCheckoutFailure).isCancelled, isFalse);
    expect(result.message, contains('Could not open'));
  });
}
