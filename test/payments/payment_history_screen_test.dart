import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/payments/payment_flow_controller.dart';
import 'package:yakku/core/payments/pending_payment_store.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/payments/razorpay_gateway.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/datasources/payment_remote_data_source.dart';
import 'package:yakku/data/models/payments/payment_models.dart';
import 'package:yakku/presentation/payments/payment_status_labels.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/screens/profile/payment_history_screen.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

import '../helpers/app_scope_fakes.dart';

class _AskBackRemote extends Fake implements AskBackRemoteDataSource {}

class _Realtime extends Fake implements AskBackRealtime {}

class _Gateway implements RazorpayGateway {
  @override
  void on(String event, Function handler) {}

  @override
  void open(Map<String, dynamic> options) {}

  @override
  void clear() {}
}

class _PaymentsStub implements PaymentRemoteDataSource {
  int historyCount = 0;
  int getOrderCount = 0;
  List<PaymentHistoryItem> items = const [];

  @override
  Future<PaymentHistoryPage> getHistory({int page = 1, int pageSize = 10}) async {
    historyCount += 1;
    return PaymentHistoryPage(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: items.length,
      totalPages: 1,
    );
  }

  @override
  Future<PaymentOrderStatus> getOrder(String orderId) async {
    getOrderCount += 1;
    return PaymentOrderStatus(
      orderId: orderId,
      status: PaymentOrderStatuses.paid,
      purchaseType: PaymentPurchaseTypes.userPlan,
      planCode: 'yakku_lite',
      planName: 'Yakku Lite',
      amountInPaise: 9900,
      currency: 'INR',
      createdAt: DateTime.utc(2026, 11, 19),
      updatedAt: DateTime.utc(2026, 11, 19),
      expiresAt: DateTime.utc(2026, 11, 26),
    );
  }

  @override
  Future<CreatePaymentOrderResponse> createOrder(
    CreatePaymentOrderRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<VerifyPaymentResponse> verify(VerifyPaymentRequest request) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _PaymentsStub payments;
  late PendingPaymentStore pending;
  late RazorpayCheckoutService checkout;
  late PaymentFlowController flow;

  setUp(() {
    payments = _PaymentsStub();
    pending = PendingPaymentStore(
      secureStorage: SecureStorageService.inMemory(),
    );
    checkout = RazorpayCheckoutService(gateway: _Gateway());
    flow = PaymentFlowController(
      payments: payments,
      pendingPayments: pending,
      checkout: checkout,
      sleeper: (_) async {},
      maxPollAttempts: 1,
      pollInterval: Duration.zero,
    );
  });

  tearDown(() {
    flow.dispose();
    checkout.dispose();
  });

  testWidgets('shows history rows and check status for processing orders',
      (tester) async {
    payments.items = [
      PaymentHistoryItem(
        orderId: 'ord-open',
        status: PaymentOrderStatuses.pending,
        purchaseType: PaymentPurchaseTypes.userPlan,
        planCode: 'yakku_lite',
        planName: 'Yakku Lite',
        amountInPaise: 9900,
        currency: 'INR',
        createdAt: DateTime.utc(2026, 11, 19),
        expiresAt: DateTime.utc(2026, 11, 26),
      ),
      PaymentHistoryItem(
        orderId: 'ord-paid',
        status: PaymentOrderStatuses.paid,
        purchaseType: PaymentPurchaseTypes.userPlan,
        planCode: 'yakku_love',
        planName: 'Yakku Love',
        amountInPaise: 29900,
        currency: 'INR',
        createdAt: DateTime.utc(2026, 11, 10),
        paidAt: DateTime.utc(2026, 11, 10),
        expiresAt: DateTime.utc(2026, 12, 10),
      ),
    ];

    final askBack = _AskBackRemote();
    final realtime = _Realtime();
    final inbox = AskBackInboxController(remote: askBack, realtime: realtime);
    final navigatorKey = GlobalKey<NavigatorState>();
    AppToast.attach(navigatorKey);

    await tester.pumpWidget(
      testAppScope(
        askBack: askBack,
        realtime: realtime,
        inbox: inbox,
        payments: payments,
        pendingPayments: pending,
        paymentFlow: flow,
        razorpayCheckout: checkout,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const PaymentHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yakku Lite'), findsOneWidget);
    expect(find.text('Yakku Love'), findsOneWidget);
    expect(find.textContaining('₹99'), findsOneWidget);
    expect(find.textContaining('₹299'), findsOneWidget);
    expect(find.text('Check status'), findsOneWidget);
    expect(find.text('PROCESSING'), findsOneWidget);
    expect(find.text('PAID'), findsOneWidget);
    expect(
      find.textContaining('Purchased'),
      findsNWidgets(2),
    );
    expect(
      find.text(
        'Expires ${PaymentStatusLabels.formatDate(DateTime.utc(2026, 12, 10))}',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Check status'));
    await tester.pump(); // progress dialog
    await tester.pumpAndSettle();
    expect(payments.getOrderCount, greaterThan(0));
    expect(find.text('Payment successful'), findsOneWidget);
    expect(find.textContaining('confirmed'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('shows pending recovery banner when local pending exists',
      (tester) async {
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
        razorpayPaymentId: 'pay_1',
        razorpaySignature: 'sig_1',
      ),
    );

    final askBack = _AskBackRemote();
    final realtime = _Realtime();
    final inbox = AskBackInboxController(remote: askBack, realtime: realtime);

    await tester.pumpWidget(
      testAppScope(
        askBack: askBack,
        realtime: realtime,
        inbox: inbox,
        payments: payments,
        pendingPayments: pending,
        paymentFlow: flow,
        razorpayCheckout: checkout,
        child: const MaterialApp(home: PaymentHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment may still be processing'), findsOneWidget);
    expect(find.text('Check payment status'), findsOneWidget);
  });
}
