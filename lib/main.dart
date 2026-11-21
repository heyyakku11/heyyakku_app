import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/firebase/firebase_options_dev.dart';
import 'package:yakku/firebase/firebase_options_production.dart';
import 'package:yakku/firebase/firebase_options_staging.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/auth/auth_token_store.dart';
import 'package:yakku/core/auth/login_auth_service.dart';
import 'package:yakku/core/auth/token_refresh_service.dart';
import 'package:yakku/core/auth/user_preferences.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/device/device_registration_service.dart';
import 'package:yakku/core/device/installation_id_store.dart';
import 'package:yakku/core/device/notification_permission_service.dart';
import 'package:yakku/core/network/api_client.dart';
import 'package:yakku/core/network/internet_connection_service.dart';
import 'package:yakku/core/network/internet_connection_service_impl.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/core/deep_link/deep_link_service.dart';
import 'package:yakku/core/router/app_router.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source_impl.dart';
import 'package:yakku/presentation/screens/splash_overlay.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';
import 'package:yakku/core/theme/app_theme.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/datasources/activity_poll_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/datasources/auth_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/device_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/check_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/poll_remote_data_source_impl.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/datasources/notification_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/payment_remote_data_source.dart';
import 'package:yakku/data/datasources/payment_remote_data_source_impl.dart';
import 'package:yakku/core/payments/checkout_user_messages.dart';
import 'package:yakku/core/payments/payment_confirm_result.dart';
import 'package:yakku/core/payments/payment_flow_controller.dart';
import 'package:yakku/core/payments/pending_payment_store.dart';
import 'package:yakku/core/payments/pending_purchase_intent.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/data/repositories/api_activity_poll_repository.dart';
import 'package:yakku/data/repositories/draft_poll_store.dart';
import 'package:yakku/data/repositories/mock_poll_repository.dart';
import 'package:yakku/data/repositories/poll_api_repository.dart';
import 'package:yakku/data/repositories/personality_card_store.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/cubit/internet/internet_cubit.dart';
import 'package:yakku/presentation/payments/entitlement_refresh.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/internet_status_listener.dart';
import 'package:yakku/presentation/widgets/yakku_plans_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app is portrait only.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  const environment = String.fromEnvironment('ENV');

  final firebaseOptions = switch (environment) {
    'dev' => DefaultFirebaseOptionsDev.currentPlatform,
    'staging' => DefaultFirebaseOptionsStaging.currentPlatform,
    'production' => DefaultFirebaseOptionsProduction.currentPlatform,
    _ => throw Exception(
      'Invalid environment "$environment". Pass --dart-define=ENV=dev|staging|production.',
    ),
  };

  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (error) {
    if (kDebugMode) {
      debugPrint('[Firebase] initializeApp failed: $error');
    }
  }

  final preferenceStorage = PreferenceStorageService();
  final userPreferences = UserPreferences(storage: preferenceStorage);
  final secureStorage = SecureStorageService();
  final tokenStore = AuthTokenStore(secureStorage: secureStorage);
  // Older versions kept a guest identity on the device. Guests no longer exist, so drop what they left
  // behind. Safe to delete once no installed version predates this.
  await secureStorage.clearKeys(['guestToken', 'guestId', 'guestExpiresAt']);
  await preferenceStorage.clearAuthPrefs(keys: ['hasEnteredAsGuest']);

  final session = await AuthController.bootstrap(
    userPreferences: userPreferences,
    tokenStore: tokenStore,
  );
  // Pending payment recovery is per signed-in user; drop orphans when logged out.
  if (!session.isUserLogged) {
    await secureStorage.clearKeys([StorageKeys.pendingPaymentOrder]);
  }
  final hasCompletedOnboarding = await userPreferences
      .getHasCompletedOnboarding();
  final draftPolls = DraftPollStore();
  await draftPolls.open();

  runApp(
    MyApp(
      isUserLogged: session.isUserLogged,
      hasCompletedOnboarding: hasCompletedOnboarding,
      phoneNumber: session.phoneNumber,
      displayName: session.displayName,
      userPreferences: userPreferences,
      preferenceStorage: preferenceStorage,
      secureStorage: secureStorage,
      tokenStore: tokenStore,
      draftPolls: draftPolls,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.isUserLogged = false,
    this.hasCompletedOnboarding = false,
    this.phoneNumber,
    this.displayName,
    this.authRemoteDataSource,
    this.pollApiRepository,
    this.activityPollRepository,
    this.userRemoteDataSource,
    this.userPreferences,
    this.preferenceStorage,
    this.secureStorage,
    this.tokenStore,
    this.internetConnectionService,
    this.deviceRegistrationService,
    required this.draftPolls,
  });

  final bool isUserLogged;
  final bool hasCompletedOnboarding;
  final String? phoneNumber;
  final String? displayName;
  final AuthRemoteDataSource? authRemoteDataSource;
  final PollApiRepository? pollApiRepository;
  final ActivityPollRepository? activityPollRepository;
  final UserRemoteDataSource? userRemoteDataSource;
  final UserPreferences? userPreferences;
  final PreferenceStorageService? preferenceStorage;
  final SecureStorageService? secureStorage;
  final AuthTokenStore? tokenStore;
  final InternetConnectionService? internetConnectionService;
  final DeviceRegistrationService? deviceRegistrationService;
  final DraftPollStore draftPolls;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ThemeController _themeController = ThemeController();
  final MockPollRepository _polls = MockPollRepository();
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  late final AuthController _authController;
  late final BackgroundApiWorker _backgroundApiWorker;
  late final LoginAuthService _loginAuth;
  late final PollApiRepository _pollApi;
  late final CheckApiRepository _checkApi;
  late final ActivityPollRepository _activityPolls;
  late final UserRemoteDataSource _userRemote;
  late final PaymentRemoteDataSource _payments;
  late final PendingPaymentStore _pendingPayments;
  late final PendingPurchaseStore _pendingPurchase;
  late final PaymentFlowController _paymentFlow;
  late final RazorpayCheckoutService _razorpayCheckout;
  late final PersonalityCardStore _personalityCards;
  late final NotificationRemoteDataSource _notifications;
  late final AskBackRemoteDataSource _askBack;
  late final AskBackRealtimeService _askBackRealtime;
  late final AskBackInboxController _askBackInbox;
  late final DeviceRegistrationService _deviceRegistration;
  late final GoRouter _router;
  late final DeepLinkService _deepLinks;
  late final InternetCubit _internetCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final preferenceStorage =
        widget.preferenceStorage ?? PreferenceStorageService();
    final secureStorage = widget.secureStorage ?? SecureStorageService();
    final tokenStore =
        widget.tokenStore ?? AuthTokenStore(secureStorage: secureStorage);
    // Tests / alternate entrypoints may skip main() bootstrap.
    if (!tokenStore.isHydrated) {
      unawaited(tokenStore.hydrate());
    }

    final unauthenticatedDio = ApiClient.create();
    final authRemote =
        widget.authRemoteDataSource ??
        AuthRemoteDataSourceImpl(unauthenticatedDio);
    final tokenRefreshService = TokenRefreshService(
      tokenStore: tokenStore,
      authRemote: authRemote,
    );

    _backgroundApiWorker = BackgroundApiWorker();

    _authController = AuthController(
      userPreferences:
          widget.userPreferences ?? UserPreferences(storage: preferenceStorage),
      tokenStore: tokenStore,
      authRemote: authRemote,
      draftPolls: widget.draftPolls,
      isUserLogged: widget.isUserLogged,
      hasCompletedOnboarding: widget.hasCompletedOnboarding,
      phoneNumber: widget.phoneNumber,
      displayName: widget.displayName,
    );
    _loginAuth = LoginAuthService(
      authController: _authController,
      worker: _backgroundApiWorker,
    );

    final authenticatedDio = ApiClient.createAuthenticated(
      tokenStore: tokenStore,
      tokenRefreshService: tokenRefreshService,
      onSessionExpired: () => _authController.clearLocalSession(),
    );

    _pollApi =
        widget.pollApiRepository ??
        PollApiRepository(PollRemoteDataSourceImpl(authenticatedDio));

    _checkApi = CheckApiRepository(CheckRemoteDataSourceImpl(authenticatedDio));

    _activityPolls =
        widget.activityPollRepository ??
        ApiActivityPollRepository(
          ActivityPollRemoteDataSourceImpl(authenticatedDio),
        );

    _userRemote =
        widget.userRemoteDataSource ??
        UserRemoteDataSourceImpl(authenticatedDio);

    _payments = PaymentRemoteDataSourceImpl(authenticatedDio);
    _pendingPayments = PendingPaymentStore(secureStorage: secureStorage);
    _pendingPurchase = PendingPurchaseStore(storage: preferenceStorage);
    _razorpayCheckout = RazorpayCheckoutService();
    _paymentFlow = PaymentFlowController(
      payments: _payments,
      pendingPayments: _pendingPayments,
      checkout: _razorpayCheckout,
    );

    _personalityCards = PersonalityCardStore(
      remote: _userRemote,
      auth: _authController,
    );

    _notifications = NotificationRemoteDataSourceImpl(authenticatedDio);

    _askBack = AskBackRemoteDataSourceImpl(authenticatedDio);
    _askBackRealtime = AskBackRealtimeService(
      // Socket auth uses the same proactive rotate-before-use path as REST.
      accessToken: () async {
        try {
          return await tokenRefreshService.ensureFreshAccessToken();
        } catch (_) {
          // Connect with whatever is left; the hub refuses it if expired.
          return tokenStore.accessToken;
        }
      },
    );
    _askBackInbox = AskBackInboxController(
      remote: _askBack,
      realtime: _askBackRealtime,
    );
    _authController.addListener(_syncAskBackWithAuth);
    _syncAskBackWithAuth();

    _deviceRegistration =
        widget.deviceRegistrationService ??
        DeviceRegistrationServiceImpl(
          authController: _authController,
          deviceRemote: DeviceRemoteDataSourceImpl(authenticatedDio),
          installationIdStore: InstallationIdStore(storage: preferenceStorage),
          permissionService: NotificationPermissionService(
            storage: preferenceStorage,
          ),
        );
    unawaited(_deviceRegistration.initialize());

    AppToast.attach(_rootNavigatorKey);
    _router = AppRouter.create(
      _authController,
      navigatorKey: _rootNavigatorKey,
    );

    // Listen from the start so a launch link is not missed; links are queued
    // until the first frame, when the router can navigate.
    _deepLinks = DeepLinkService()
      ..initialize(onLink: (link) => _router.go(link.location));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _deepLinks.markReady();
    });

    final internetService =
        widget.internetConnectionService ?? InternetConnectionServiceImpl();
    _internetCubit = InternetCubit(internetService);
    unawaited(_internetCubit.initialize());
  }

  bool _askBackStarted = false;

  /// Ask back is for signed-in users: start the list (and its socket) on
  /// sign-in, and drop both on sign-out. Pending payment / purchase recovery
  /// belongs to the signed-in user, so clear it on sign-out.
  void _syncAskBackWithAuth() {
    final signedIn = _authController.isLoggedIn;
    if (signedIn && !_askBackStarted) {
      _askBackStarted = true;
      unawaited(_askBackInbox.start());
      unawaited(_resumePendingPurchaseAfterAuth());
      unawaited(_reconcilePendingPaymentQuietly());
    } else if (!signedIn) {
      if (_askBackStarted) {
        _askBackStarted = false;
        unawaited(_askBackInbox.reset());
      }
      unawaited(_pendingPayments.clear());
      unawaited(_pendingPurchase.clear());
    }
  }

  /// After sign-in, reopen plans with the plan the user tried to buy while
  /// signed out. Catalog and current plan are reloaded from the backend.
  Future<void> _resumePendingPurchaseAfterAuth() async {
    final intent = await _pendingPurchase.read();
    if (intent == null) return;

    // Let the router finish moving from sign-up onto the main shell.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || !_authController.isLoggedIn) return;

    await _pendingPurchase.clear();
    if (!mounted || !_authController.isLoggedIn) return;

    final context = _rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    await showYakkuPlans(
      context,
      contentType: intent.contentType,
      contentId: intent.contentId,
      initialPlanCode: intent.planCode,
    );
  }

  /// Network-after-pay / interrupted Checkout recovery. Never creates a new
  /// order — only retries verify when a payload exists, else polls status.
  Future<void> _reconcilePendingPaymentQuietly() async {
    if (!_authController.isLoggedIn) return;
    if (_paymentFlow.isBusy) return;
    try {
      final result = await _paymentFlow.reconcilePendingPayment();
      if (result == null || !mounted) return;

      final message = CheckoutUserMessages.forConfirmResult(
        result,
        notifyPending: false,
      );
      if (message != null) AppToast.show(message);

      if (result is PaymentConfirmFulfilled) {
        await EntitlementRefresh.afterFulfillment(
          userRemote: _userRemote,
          personalityCards: _personalityCards,
          askBack: _askBack,
          askBackInbox: _askBackInbox,
          contentType: result.contentType,
          contentId: result.contentId,
        );
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[Payments] pending reconcile failed: $error\n$stack');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_internetCubit.refresh());
      if (_askBackStarted) {
        // Bring the socket back after the app was in the background.
        unawaited(_askBackRealtime.ensureConnected().catchError((Object _) {}));
      }
      if (_authController.isLoggedIn) {
        unawaited(_reconcilePendingPaymentQuietly());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authController.removeListener(_syncAskBackWithAuth);
    _personalityCards.dispose();
    _askBackInbox.dispose();
    unawaited(_askBackRealtime.dispose());
    _paymentFlow.dispose();
    _razorpayCheckout.dispose();
    _themeController.dispose();
    _authController.dispose();
    _backgroundApiWorker.dispose();
    _deviceRegistration.dispose();
    _polls.dispose();
    unawaited(widget.draftPolls.close());
    unawaited(_deepLinks.dispose());
    _router.dispose();
    unawaited(_internetCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<InternetCubit>.value(value: _internetCubit)],
      child: AppScope(
        themeController: _themeController,
        authController: _authController,
        loginAuth: _loginAuth,
        backgroundApiWorker: _backgroundApiWorker,
        polls: _polls,
        pollApi: _pollApi,
        checkApi: _checkApi,
        activityPolls: _activityPolls,
        userRemote: _userRemote,
        payments: _payments,
        pendingPayments: _pendingPayments,
        pendingPurchase: _pendingPurchase,
        paymentFlow: _paymentFlow,
        razorpayCheckout: _razorpayCheckout,
        personalityCards: _personalityCards,
        notifications: _notifications,
        deviceRegistration: _deviceRegistration,
        draftPolls: widget.draftPolls,
        askBack: _askBack,
        askBackRealtime: _askBackRealtime,
        askBackInbox: _askBackInbox,
        child: ListenableBuilder(
          listenable: _themeController,
          builder: (context, _) {
            return MaterialApp.router(
              title: 'Yakku',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: _themeController.themeMode,
              routerConfig: _router,
              builder: (context, child) {
                return SplashOverlay(
                  child: InternetStatusListener(child: child),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
