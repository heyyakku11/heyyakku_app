import 'package:flutter/material.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/repositories/mock_poll_repository.dart';
import 'package:yakku/domain/repositories/poll_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.themeController,
    required this.authController,
    required this.polls,
    required super.child,
  });

  final ThemeController themeController;
  final AuthController authController;
  final MockPollRepository polls;

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
        polls != oldWidget.polls;
  }
}
