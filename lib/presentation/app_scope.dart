import 'package:flutter/material.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/auth/guest_session_service.dart';
import 'package:yakku/core/auth/guest_token_store.dart';
import 'package:yakku/core/auth/login_auth_service.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/device/device_registration_service.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/datasources/guest_remote_data_source.dart';
import 'package:yakku/data/datasources/notification_preference_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/data/repositories/draft_poll_store.dart';
import 'package:yakku/data/repositories/mock_poll_repository.dart';
import 'package:yakku/data/repositories/poll_api_repository.dart';
import 'package:yakku/domain/repositories/poll_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.themeController,
    required this.authController,
    required this.guestRemote,
    required this.guestTokenStore,
    required this.guestSession,
    required this.loginAuth,
    required this.backgroundApiWorker,
    required this.polls,
    required this.pollApi,
    required this.activityPolls,
    required this.userRemote,
    required this.notificationPreferences,
    required this.deviceRegistration,
    required this.draftPolls,
    required super.child,
  });

  final ThemeController themeController;
  final AuthController authController;
  final GuestRemoteDataSource guestRemote;
  final GuestTokenStore guestTokenStore;
  final GuestSessionService guestSession;
  final LoginAuthService loginAuth;
  final BackgroundApiWorker backgroundApiWorker;
  final MockPollRepository polls;
  final PollApiRepository pollApi;
  final ActivityPollRepository activityPolls;
  final UserRemoteDataSource userRemote;
  final NotificationPreferenceRemoteDataSource notificationPreferences;
  final DeviceRegistrationService deviceRegistration;
  final DraftPollStore draftPolls;

  PollRepository get repository => polls;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return themeController != oldWidget.themeController ||
        authController != oldWidget.authController ||
        guestRemote != oldWidget.guestRemote ||
        guestTokenStore != oldWidget.guestTokenStore ||
        guestSession != oldWidget.guestSession ||
        loginAuth != oldWidget.loginAuth ||
        backgroundApiWorker != oldWidget.backgroundApiWorker ||
        polls != oldWidget.polls ||
        pollApi != oldWidget.pollApi ||
        activityPolls != oldWidget.activityPolls ||
        userRemote != oldWidget.userRemote ||
        notificationPreferences != oldWidget.notificationPreferences ||
        deviceRegistration != oldWidget.deviceRegistration ||
        draftPolls != oldWidget.draftPolls;
  }
}
