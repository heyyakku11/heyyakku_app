import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/payments/pending_payment_store.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';

void main() {
  late PendingPaymentStore store;

  setUp(() {
    store = PendingPaymentStore(
      secureStorage: SecureStorageService.inMemory(),
    );
  });

  PendingPayment sample({
    String orderId = 'order-1',
    String? paymentId,
    String? signature,
  }) {
    return PendingPayment(
      orderId: orderId,
      razorpayOrderId: 'order_ABC',
      planCode: 'yakku_lite',
      planName: 'Yakku Lite',
      purchaseType: 'UserPlan',
      amountInPaise: 9900,
      currency: 'INR',
      savedAt: DateTime.utc(2026, 11, 19, 10),
      razorpayPaymentId: paymentId,
      razorpaySignature: signature,
    );
  }

  test('round-trips a pending order', () async {
    await store.save(sample());
    final loaded = await store.read();
    expect(loaded, isNotNull);
    expect(loaded!.orderId, 'order-1');
    expect(loaded.razorpayOrderId, 'order_ABC');
    expect(loaded.hasVerifyPayload, isFalse);
  });

  test('stores verify callback fields via copyWith', () async {
    final withCallback = sample().copyWith(
      razorpayPaymentId: 'pay_1',
      razorpaySignature: 'sig_1',
    );
    await store.save(withCallback);
    final loaded = await store.read();
    expect(loaded!.hasVerifyPayload, isTrue);
    expect(loaded.razorpayPaymentId, 'pay_1');
  });

  test('clearIfOrder only clears matching order', () async {
    await store.save(sample(orderId: 'order-1'));
    await store.clearIfOrder('other');
    expect((await store.read())?.orderId, 'order-1');
    await store.clearIfOrder('order-1');
    expect(await store.read(), isNull);
  });

  test('clear removes the pending order', () async {
    await store.save(sample());
    await store.clear();
    expect(await store.read(), isNull);
  });
}
