import 'package:flutter/material.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/device/device_registration_service.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/data/repositories/mock_poll_repository.dart';
import 'package:yakku/data/repositories/poll_api_repository.dart';
import 'package:yakku/domain/repositories/poll_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.themeController,
    required this.authController,
    required this.polls,
    required this.pollApi,
    required this.activityPolls,
    required this.userRemote,
    required this.notifications,
    required this.deviceRegistration,
    required super.child,
  });

  final ThemeController themeController;
  final AuthController authController;
  final MockPollRepository polls;
  final PollApiRepository pollApi;
  final ActivityPollRepository activityPolls;
  final UserRemoteDataSource userRemote;
  final NotificationRemoteDataSource notifications;
  final DeviceRegistrationService deviceRegistration;

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
        polls != oldWidget.polls ||
        pollApi != oldWidget.pollApi ||
        activityPolls != oldWidget.activityPolls ||
        userRemote != oldWidget.userRemote ||
        notifications != oldWidget.notifications ||
        deviceRegistration != oldWidget.deviceRegistration;
  }
}
