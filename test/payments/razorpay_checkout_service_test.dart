import 'package:flutter_test/flutter_test.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/payments/razorpay_gateway.dart';
import 'package:yakku/data/models/payments/payment_models.dart';

class _FakeGateway implements RazorpayGateway {
  final Map<String, Function> handlers = {};
  Map<String, dynamic>? lastOptions;
  int openCount = 0;
  int clearCount = 0;
  Object? openError;

  @override
  void on(String event, Function handler) {
    handlers[event] = handler;
  }

  @override
  void open(Map<String, dynamic> options) {
    openCount += 1;
    lastOptions = options;
    if (openError != null) {
      throw openError!;
    }
  }

  @override
  void clear() {
    clearCount += 1;
    handlers.clear();
  }

  void emitSuccess({
    String paymentId = 'pay_1',
    String orderId = 'order_ABC',
    String signature = 'sig_1',
  }) {
    handlers[RazorpayGatewayEvents.paymentSuccess]?.call(
      PaymentSuccessResponse(paymentId, orderId, signature, null),
    );
  }

  void emitError({
    int code = RazorpayGatewayErrorCodes.unknownError,
    String message = 'failed',
  }) {
    handlers[RazorpayGatewayEvents.paymentError]?.call(
      PaymentFailureResponse(code, message, null),
    );
  }

  void emitCancelled() {
    emitError(
      code: RazorpayGatewayErrorCodes.paymentCancelled,
      message: 'Payment cancelled by user',
    );
  }

  void emitExternalWallet([String name = 'paytm']) {
    handlers[RazorpayGatewayEvents.externalWallet]?.call(
      ExternalWalletResponse(name),
    );
  }
}

RazorpayCheckoutOptions sampleOptions({
  String key = 'rzp_test_123',
  String orderId = 'order_ABC',
  int amount = 9900,
  String? internalOrderId = 'internal-1',
}) {
  return RazorpayCheckoutOptions(
    razorpayKeyId: key,
    razorpayOrderId: orderId,
    amountInPaise: amount,
    currency: 'INR',
    description: 'Yakku Lite',
    contact: '9999999999',
    internalOrderId: internalOrderId,
  );
}

void main() {
  late _FakeGateway gateway;
  late RazorpayCheckoutService service;

  setUp(() {
    gateway = _FakeGateway();
    service = RazorpayCheckoutService(gateway: gateway);
  });

  tearDown(() {
    service.dispose();
  });

  test('open builds SDK options from backend order fields only', () async {
    final future = service.open(sampleOptions());
    expect(service.isSessionActive, isTrue);
    expect(gateway.openCount, 1);
    expect(gateway.lastOptions?['key'], 'rzp_test_123');
    expect(gateway.lastOptions?['order_id'], 'order_ABC');
    expect(gateway.lastOptions?['amount'], 9900);
    expect(gateway.lastOptions?['currency'], 'INR');
    expect(gateway.lastOptions?['name'], 'Yakku');
    expect(gateway.lastOptions?['prefill'], {'contact': '9999999999'});
    expect(gateway.lastOptions?['method'], isA<Map>());
    expect(gateway.lastOptions?['notes'], {'yakku_order_id': 'internal-1'});
    expect(gateway.lastOptions?.containsKey('key_secret'), isFalse);

    gateway.emitSuccess();
    final result = await future;
    expect(result, isA<RazorpayCheckoutSuccess>());
  });

  test('fromOrder maps CreatePaymentOrderResponse', () {
    final options = RazorpayCheckoutOptions.fromOrder(
      CreatePaymentOrderResponse(
        orderId: 'internal-1',
        razorpayOrderId: 'order_ABC',
        razorpayKeyId: 'rzp_test_123',
        amountInPaise: 29900,
        currency: 'INR',
        purchaseType: 'UserPlan',
        planCode: 'yakku_love',
        planName: 'Yakku Love',
        status: 'Pending',
        expiresAt: DateTime.utc(2026, 11, 20),
      ),
      contact: '9000000000',
    );
    expect(options.internalOrderId, 'internal-1');
    expect(options.description, 'Yakku Love');
    expect(options.amountInPaise, 29900);
  });

  test('success callback completes once and ignores duplicates', () async {
    final future = service.open(sampleOptions());
    gateway.emitSuccess();
    gateway.emitSuccess(paymentId: 'pay_dup');
    final result = await future;
    expect(result, isA<RazorpayCheckoutSuccess>());
    final success = result as RazorpayCheckoutSuccess;
    expect(success.razorpayPaymentId, 'pay_1');
    expect(success.internalOrderId, 'internal-1');
    expect(service.isSessionActive, isFalse);
  });

  test('cancelled payment is marked isCancelled', () async {
    final future = service.open(sampleOptions());
    gateway.emitCancelled();
    final result = await future;
    expect(result, isA<RazorpayCheckoutFailure>());
    final failure = result as RazorpayCheckoutFailure;
    expect(failure.isCancelled, isTrue);
  });

  test('failure callback returns non-cancelled failure', () async {
    final future = service.open(sampleOptions());
    gateway.emitError(message: 'Card declined');
    final result = await future as RazorpayCheckoutFailure;
    expect(result.isCancelled, isFalse);
    expect(result.message, 'Card declined');
  });

  test('external wallet does not complete the session', () async {
    final future = service.open(sampleOptions());
    gateway.emitExternalWallet('phonepe');
    expect(service.isSessionActive, isTrue);
    expect(service.lastExternalWallet, 'phonepe');
    gateway.emitSuccess();
    await future;
  });

  test('rejects a second simultaneous checkout', () async {
    final first = service.open(sampleOptions());
    expect(
      () => service.open(sampleOptions(orderId: 'order_OTHER')),
      throwsA(isA<RazorpayCheckoutException>()),
    );
    gateway.emitCancelled();
    await first;
  });

  test('rejects incomplete checkout options', () {
    expect(
      () => service.open(sampleOptions(key: '')),
      throwsA(isA<RazorpayCheckoutException>()),
    );
    expect(gateway.openCount, 0);
  });

  test('SDK open exception resets session state', () {
    gateway.openError = Exception('native boom');
    expect(
      () => service.open(sampleOptions()),
      throwsA(isA<RazorpayCheckoutException>()),
    );
    expect(service.isSessionActive, isFalse);
    expect(service.isOpening, isFalse);
  });

  test('markInterrupted completes an open session as cancelled', () async {
    final future = service.open(sampleOptions());
    service.markInterrupted();
    final result = await future as RazorpayCheckoutFailure;
    expect(result.isCancelled, isTrue);
    expect(service.isSessionActive, isFalse);
  });

  test('dispose clears gateway listeners', () {
    service.dispose();
    expect(gateway.clearCount, 1);
  });

  test('incomplete success payload becomes failure', () async {
    final future = service.open(sampleOptions());
    gateway.handlers[RazorpayGatewayEvents.paymentSuccess]?.call(
      PaymentSuccessResponse('pay_1', null, null, null),
    );
    final result = await future as RazorpayCheckoutFailure;
    expect(result.isCancelled, isFalse);
  });
}
