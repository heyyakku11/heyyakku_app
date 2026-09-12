import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/auth/user_preferences.dart';
import 'package:yakku/core/network/api_client.dart';
import 'package:yakku/core/network/internet_connection_service.dart';
import 'package:yakku/core/network/internet_connection_service_impl.dart';
import 'package:yakku/core/router/app_router.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/theme/app_theme.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/repositories/mock_poll_repository.dart';
import 'package:yakku/data/datasources/auth_remote_data_source_impl.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/cubit/internet/internet_cubit.dart';
import 'package:yakku/presentation/widgets/internet_status_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferenceStorage = PreferenceStorageService();
  final userPreferences = UserPreferences(storage: preferenceStorage);
  final secureStorage = SecureStorageService();
  final session = await AuthController.bootstrap(
    userPreferences: userPreferences,
    secureStorage: secureStorage,
  );

  runApp(
    MyApp(
      isUserLogged: session.isUserLogged,
      email: session.email,
      displayName: session.displayName,
      userPreferences: userPreferences,
      secureStorage: secureStorage,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.isUserLogged = false,
    this.email,
    this.displayName,
    this.authRemoteDataSource,
    this.userPreferences,
    this.secureStorage,
    this.internetConnectionService,
  });

  final bool isUserLogged;
  final String? email;
  final String? displayName;
  final AuthRemoteDataSource? authRemoteDataSource;
  final UserPreferences? userPreferences;
  final SecureStorageService? secureStorage;
  final InternetConnectionService? internetConnectionService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ThemeController _themeController = ThemeController();
  final MockPollRepository _polls = MockPollRepository();
  late final AuthController _authController;
  late final GoRouter _router;
  late final InternetCubit _internetCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final authRemote =
        widget.authRemoteDataSource ?? AuthRemoteDataSourceImpl(ApiClient.create());
    _authController = AuthController(
      userPreferences: widget.userPreferences ?? UserPreferences(),
      secureStorage: widget.secureStorage ?? SecureStorageService(),
      authRemote: authRemote,
      isUserLogged: widget.isUserLogged,
      email: widget.email,
      displayName: widget.displayName,
    );
    _router = AppRouter.create(_authController);

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
    _polls.dispose();
    _router.dispose();
    unawaited(_internetCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<InternetCubit>.value(value: _internetCubit),
      ],
      child: AppScope(
        themeController: _themeController,
        authController: _authController,
        polls: _polls,
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
                return InternetStatusListener(child: child);
              },
            );
          },
        ),
      ),
    );
  }
}
