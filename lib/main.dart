import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/auth/auth_token_store.dart';
import 'package:yakku/core/auth/guest_session_service.dart';
import 'package:yakku/core/auth/guest_token_store.dart';
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
import 'package:yakku/core/router/app_router.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/theme/app_theme.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/datasources/activity_poll_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/datasources/auth_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/device_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/guest_remote_data_source.dart';
import 'package:yakku/data/datasources/guest_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/notification_preference_remote_data_source.dart';
import 'package:yakku/data/datasources/notification_preference_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/media_upload_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/check_remote_data_source_impl.dart';
import 'package:yakku/data/datasources/poll_remote_data_source_impl.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source_impl.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/data/repositories/api_activity_poll_repository.dart';
import 'package:yakku/data/repositories/draft_poll_store.dart';
import 'package:yakku/data/repositories/media_upload_repository.dart';
import 'package:yakku/data/repositories/mock_poll_repository.dart';
import 'package:yakku/data/repositories/poll_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/cubit/internet/internet_cubit.dart';
import 'package:yakku/presentation/widgets/background_job_effects.dart';
import 'package:yakku/presentation/widgets/internet_status_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (error) {
    if (kDebugMode) {
      debugPrint('[Firebase] initializeApp failed: $error');
    }
  }

  final preferenceStorage = PreferenceStorageService();
  final userPreferences = UserPreferences(storage: preferenceStorage);
  final secureStorage = SecureStorageService();
  final tokenStore = AuthTokenStore(secureStorage: secureStorage);
  final session = await AuthController.bootstrap(
    userPreferences: userPreferences,
    tokenStore: tokenStore,
  );
  final draftPolls = DraftPollStore();
  await draftPolls.open();

  runApp(
    MyApp(
      isUserLogged: session.isUserLogged,
      hasEnteredAsGuest: session.hasEnteredAsGuest,
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
    this.hasEnteredAsGuest = false,
    this.phoneNumber,
    this.displayName,
    this.authRemoteDataSource,
    this.guestRemoteDataSource,
    this.guestTokenStore,
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
  final bool hasEnteredAsGuest;
  final String? phoneNumber;
  final String? displayName;
  final AuthRemoteDataSource? authRemoteDataSource;
  final GuestRemoteDataSource? guestRemoteDataSource;
  final GuestTokenStore? guestTokenStore;
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
  late final GuestRemoteDataSource _guestRemote;
  late final GuestTokenStore _guestTokenStore;
  late final BackgroundApiWorker _backgroundApiWorker;
  late final GuestSessionService _guestSession;
  late final LoginAuthService _loginAuth;
  late final PollApiRepository _pollApi;
  late final CheckApiRepository _checkApi;
  late final MediaUploadRepository _mediaUploads;
  late final ActivityPollRepository _activityPolls;
  late final UserRemoteDataSource _userRemote;
  late final NotificationPreferenceRemoteDataSource _notificationPreferences;
  late final DeviceRegistrationService _deviceRegistration;
  late final GoRouter _router;
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

    _guestTokenStore =
        widget.guestTokenStore ?? GuestTokenStore(secureStorage: secureStorage);
    if (!_guestTokenStore.isHydrated) {
      unawaited(_guestTokenStore.hydrate());
    }
    _guestRemote =
        widget.guestRemoteDataSource ??
        GuestRemoteDataSourceImpl(unauthenticatedDio);
    _backgroundApiWorker = BackgroundApiWorker();
    _guestSession = GuestSessionService(
      guestRemote: _guestRemote,
      guestTokenStore: _guestTokenStore,
      worker: _backgroundApiWorker,
    );

    _authController = AuthController(
      userPreferences:
          widget.userPreferences ?? UserPreferences(storage: preferenceStorage),
      tokenStore: tokenStore,
      authRemote: authRemote,
      draftPolls: widget.draftPolls,
      isUserLogged: widget.isUserLogged,
      hasEnteredAsGuest: widget.hasEnteredAsGuest,
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

    _mediaUploads = MediaUploadRepository(
      MediaUploadRemoteDataSourceImpl(apiDio: authenticatedDio),
    );

    _activityPolls =
        widget.activityPollRepository ??
        ApiActivityPollRepository(
          ActivityPollRemoteDataSourceImpl(authenticatedDio),
        );

    _userRemote =
        widget.userRemoteDataSource ??
        UserRemoteDataSourceImpl(authenticatedDio);

    _notificationPreferences = NotificationPreferenceRemoteDataSourceImpl(
      authenticatedDio,
    );

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

    _router = AppRouter.create(
      _authController,
      navigatorKey: _rootNavigatorKey,
    );

    final internetService =
        widget.internetConnectionService ?? InternetConnectionServiceImpl();
    _internetCubit = InternetCubit(internetService);
    unawaited(_internetCubit.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_internetCubit.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeController.dispose();
    _authController.dispose();
    _backgroundApiWorker.dispose();
    _deviceRegistration.dispose();
    _polls.dispose();
    unawaited(widget.draftPolls.close());
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
        guestRemote: _guestRemote,
        guestTokenStore: _guestTokenStore,
        guestSession: _guestSession,
        loginAuth: _loginAuth,
        backgroundApiWorker: _backgroundApiWorker,
        polls: _polls,
        pollApi: _pollApi,
        checkApi: _checkApi,
        mediaUploads: _mediaUploads,
        activityPolls: _activityPolls,
        userRemote: _userRemote,
        notificationPreferences: _notificationPreferences,
        deviceRegistration: _deviceRegistration,
        draftPolls: widget.draftPolls,
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
                return BackgroundJobEffects(
                  worker: _backgroundApiWorker,
                  authController: _authController,
                  guestTokenStore: _guestTokenStore,
                  navigatorKey: _rootNavigatorKey,
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
