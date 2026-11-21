import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/payments/payment_error_codes.dart';
import 'package:yakku/core/payments/payment_flow_controller.dart';
import 'package:yakku/core/payments/pending_payment_store.dart';
import 'package:yakku/core/payments/pending_purchase_intent.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/payments/razorpay_gateway.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/datasources/payment_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/payments/payment_models.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/yakku_plans_sheet.dart';

import '../helpers/app_scope_fakes.dart';

class _AuthStub extends Fake implements AuthController {
  _AuthStub({required this.loggedIn, this.phone});

  final bool loggedIn;
  final String? phone;

  @override
  bool get isLoggedIn => loggedIn;

  @override
  String? get phoneNumber => phone;
}

class _PlansUserRemote extends Fake implements UserRemoteDataSource {
  @override
  Future<List<YakkuPlan>> listPlans() async => const [];

  @override
  Future<UserProfileResponse> getMe() async {
    return UserProfileResponse(
      profile: const UserProfileDetails(anonymousName: 'Anon'),
      account: const UserAccountDetails(
        status: 'Active',
        phoneNumber: '9999999999',
      ),
      stats: const UserStatsDetails(
        cardsMade: 0,
        votesCast: 0,
        streak: UserStreakSummary(currentStreak: 0, longestStreak: 0),
      ),
    );
  }
}

class _AskBackRemote extends Fake implements AskBackRemoteDataSource {}

class _Realtime extends Fake implements AskBackRealtime {}

class _PaymentsStub implements PaymentRemoteDataSource {
  CreatePaymentOrderRequest? lastRequest;
  VerifyPaymentRequest? lastVerify;
  Object? error;
  Object? verifyError;
  int createCount = 0;
  int verifyCount = 0;
  int getOrderCount = 0;
  VerifyPaymentResponse? verifyResponse;
  final List<PaymentOrderStatus> statusQueue = [];

  @override
  Future<CreatePaymentOrderResponse> createOrder(
    CreatePaymentOrderRequest request,
  ) async {
    createCount += 1;
    lastRequest = request;
    if (error != null) throw error!;
    return CreatePaymentOrderResponse(
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
  Future<PaymentOrderStatus> getOrder(String orderId) async {
    getOrderCount += 1;
    if (statusQueue.isNotEmpty) return statusQueue.removeAt(0);
    return PaymentOrderStatus(
      orderId: orderId,
      status: PaymentOrderStatuses.pending,
      purchaseType: PaymentPurchaseTypes.userPlan,
      planCode: YakkuPlan.liteCode,
      planName: 'Yakku Lite',
      amountInPaise: 9900,
      currency: 'INR',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<PaymentHistoryPage> getHistory({int page = 1, int pageSize = 10}) {
    throw UnimplementedError();
  }

  @override
  Future<VerifyPaymentResponse> verify(VerifyPaymentRequest request) async {
    verifyCount += 1;
    lastVerify = request;
    if (verifyError != null) throw verifyError!;
    return verifyResponse ??
        const VerifyPaymentResponse(
          orderId: 'ord-1',
          status: PaymentOrderStatuses.paid,
          alreadyFulfilled: false,
          purchaseType: PaymentPurchaseTypes.userPlan,
          planCode: YakkuPlan.liteCode,
        );
  }
}

class _GatewayStub implements RazorpayGateway {
  final Map<String, Function> handlers = {};
  int openCount = 0;
  Map<String, dynamic>? lastOptions;

  @override
  void on(String event, Function handler) {
    handlers[event] = handler;
  }

  @override
  void open(Map<String, dynamic> options) {
    openCount += 1;
    lastOptions = options;
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

  void emitError({
    int code = RazorpayGatewayErrorCodes.unknownError,
    String message = 'failed',
  }) {
    handlers[RazorpayGatewayEvents.paymentError]?.call(
      PaymentFailureResponse(code, message, null),
    );
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
}

const _lite = YakkuPlan(
  id: 'lite',
  code: YakkuPlan.liteCode,
  name: 'Yakku Lite',
  priceMinor: 9900,
  currency: 'INR',
  durationDays: 7,
  unlockTickets: 3,
  askBackMessageLimit: 3,
);

const _love = YakkuPlan(
  id: 'love',
  code: YakkuPlan.loveCode,
  name: 'Yakku Love',
  priceMinor: 29900,
  currency: 'INR',
  durationDays: 30,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PendingPurchaseStore purchaseStore;
  late PendingPaymentStore pendingPayments;
  late _PaymentsStub payments;
  late _GatewayStub gateway;
  late RazorpayCheckoutService checkout;
  late PaymentFlowController paymentFlow;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    purchaseStore = PendingPurchaseStore(storage: PreferenceStorageService());
    pendingPayments = PendingPaymentStore(
      secureStorage: SecureStorageService.inMemory(),
    );
    payments = _PaymentsStub();
    gateway = _GatewayStub();
    checkout = RazorpayCheckoutService(gateway: gateway);
    paymentFlow = PaymentFlowController(
      payments: payments,
      pendingPayments: pendingPayments,
      checkout: checkout,
      sleeper: (_) async {},
      maxPollAttempts: 3,
      pollInterval: Duration.zero,
    );
  });

  tearDown(() {
    paymentFlow.dispose();
    checkout.dispose();
  });

  testWidgets('signed-out buy saves intent and opens sign-up', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final askBack = _AskBackRemote();
    final realtime = _Realtime();
    final inbox = AskBackInboxController(remote: askBack, realtime: realtime);
    final navigatorKey = GlobalKey<NavigatorState>();
    AppToast.attach(navigatorKey);

    final router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      showModalBottomSheet<CreatePaymentOrderResponse>(
                        context: context,
                        builder: (_) => const YakkuPlansSheet(
                          initialCatalog: [_lite, _love],
                        ),
                      );
                    },
                    child: const Text('Open plans'),
                  ),
                ),
              );
            },
          ),
        ),
        GoRoute(
          path: AppRoutes.signUp,
          builder: (_, _) => const Scaffold(body: Text('Sign up')),
        ),
      ],
    );

    await tester.pumpWidget(
      testAppScope(
        askBack: askBack,
        realtime: realtime,
        inbox: inbox,
        userRemote: _PlansUserRemote(),
        authController: _AuthStub(loggedIn: false),
        pendingPurchase: purchaseStore,
        payments: payments,
        pendingPayments: pendingPayments,
        paymentFlow: paymentFlow,
        razorpayCheckout: checkout,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open plans'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Get Yakku Lite'), findsOneWidget);

    await tester.tap(find.textContaining('Get Yakku Lite'));
    await tester.pumpAndSettle();

    final intent = await purchaseStore.read();
    expect(intent, isNotNull);
    expect(intent!.planCode, YakkuPlan.liteCode);
    expect(find.text('Sign up'), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.signUp);
    expect(payments.createCount, 0);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('signed-in buy creates order and pops checkout payload',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final askBack = _AskBackRemote();
    final realtime = _Realtime();
    final inbox = AskBackInboxController(remote: askBack, realtime: realtime);
    CreatePaymentOrderResponse? created;

    await tester.pumpWidget(
      testAppScope(
        askBack: askBack,
        realtime: realtime,
        inbox: inbox,
        userRemote: _PlansUserRemote(),
        authController: _AuthStub(loggedIn: true, phone: '9999999999'),
        pendingPurchase: purchaseStore,
        payments: payments,
        pendingPayments: pendingPayments,
        paymentFlow: paymentFlow,
        razorpayCheckout: checkout,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      created =
                          await showModalBottomSheet<CreatePaymentOrderResponse>(
                        context: context,
                        builder: (_) => const YakkuPlansSheet(
                          initialCatalog: [_lite],
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Get Yakku Lite'));
    await tester.pumpAndSettle();

    expect(created?.orderId, 'ord-1');
    expect(created?.razorpayOrderId, 'order_ABC');
    expect(payments.createCount, 1);
    expect(payments.lastRequest!.planId, 'lite');
    expect(await purchaseStore.read(), isNull);
    expect((await pendingPayments.read())?.orderId, 'ord-1');
  });

  testWidgets('order create business error keeps sheet open', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    payments.error = const ApiException(
      kind: ApiErrorKind.conflict,
      message: 'Already active',
      code: PaymentErrorCodes.planAlreadyActive,
    );

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
        userRemote: _PlansUserRemote(),
        authController: _AuthStub(loggedIn: true),
        pendingPurchase: purchaseStore,
        payments: payments,
        pendingPayments: pendingPayments,
        paymentFlow: paymentFlow,
        razorpayCheckout: checkout,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      showModalBottomSheet<CreatePaymentOrderResponse>(
                        context: context,
                        builder: (_) => const YakkuPlansSheet(
                          initialCatalog: [_lite],
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Get Yakku Lite'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Get Yakku Lite'), findsOneWidget);
    expect(find.text('You already have this plan.'), findsOneWidget);
    expect(await pendingPayments.read(), isNull);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('showYakkuPlans verifies checkout success and returns true',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final askBack = _AskBackRemote();
    final realtime = _Realtime();
    final inbox = AskBackInboxController(remote: askBack, realtime: realtime);
    final navigatorKey = GlobalKey<NavigatorState>();
    AppToast.attach(navigatorKey);
    var bought = false;

    await tester.pumpWidget(
      testAppScope(
        askBack: askBack,
        realtime: realtime,
        inbox: inbox,
        userRemote: _PlansUserRemote(),
        authController: _AuthStub(loggedIn: true, phone: '+91 99999 99999'),
        pendingPurchase: purchaseStore,
        payments: payments,
        pendingPayments: pendingPayments,
        paymentFlow: paymentFlow,
        razorpayCheckout: checkout,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      bought = await showYakkuPlans(
                        context,
                        catalog: const [_lite],
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Get Yakku Lite'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(gateway.openCount, 1);
    expect(gateway.lastOptions!['order_id'], 'order_ABC');
    expect(
      (gateway.lastOptions!['prefill'] as Map)['contact'],
      '9999999999',
    );

    gateway.emitSuccess();
    await tester.pumpAndSettle();

    expect(payments.verifyCount, 1);
    expect(payments.lastVerify!.razorpayPaymentId, 'pay_1');
    expect(find.text('Payment successful'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(bought, isTrue);
    expect(await pendingPayments.read(), isNull);
  });

  testWidgets('checkout failure reconciles status then shows outcome',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
        userRemote: _PlansUserRemote(),
        authController: _AuthStub(loggedIn: true, phone: '9999999999'),
        pendingPurchase: purchaseStore,
        payments: payments,
        pendingPayments: pendingPayments,
        paymentFlow: paymentFlow,
        razorpayCheckout: checkout,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      showYakkuPlans(context, catalog: const [_lite]);
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Get Yakku Lite'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    gateway.emitError(message: 'Card declined');
    await tester.pumpAndSettle();
    expect(payments.getOrderCount, greaterThan(0));
    expect(find.text('Card declined'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('checkout cancel still succeeds when backend already Paid',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    payments.statusQueue.add(
      PaymentOrderStatus(
        orderId: 'ord-1',
        status: PaymentOrderStatuses.paid,
        purchaseType: PaymentPurchaseTypes.userPlan,
        planCode: YakkuPlan.liteCode,
        planName: 'Yakku Lite',
        amountInPaise: 9900,
        currency: 'INR',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
      ),
    );

    final askBack = _AskBackRemote();
    final realtime = _Realtime();
    final inbox = AskBackInboxController(remote: askBack, realtime: realtime);
    final navigatorKey = GlobalKey<NavigatorState>();
    AppToast.attach(navigatorKey);
    var bought = false;

    await tester.pumpWidget(
      testAppScope(
        askBack: askBack,
        realtime: realtime,
        inbox: inbox,
        userRemote: _PlansUserRemote(),
        authController: _AuthStub(loggedIn: true, phone: '9999999999'),
        pendingPurchase: purchaseStore,
        payments: payments,
        pendingPayments: pendingPayments,
        paymentFlow: paymentFlow,
        razorpayCheckout: checkout,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      bought = await showYakkuPlans(
                        context,
                        catalog: const [_lite],
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Get Yakku Lite'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    gateway.emitCancelled();
    await tester.pumpAndSettle();

    expect(find.text('Payment successful'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(bought, isTrue);
    expect(await pendingPayments.read(), isNull);
  });
}
