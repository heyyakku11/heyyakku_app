import 'package:flutter/material.dart';
import 'package:yakku/core/theme/app_theme.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/repositories/mock_poll_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeController _themeController = ThemeController();
  final MockPollRepository _polls = MockPollRepository();

  @override
  void dispose() {
    _themeController.dispose();
    _polls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      themeController: _themeController,
      polls: _polls,
      child: ListenableBuilder(
        listenable: _themeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'Yakku',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _themeController.themeMode,
            home: const MyYakku(),
          );
        },
      ),
    );
  }
}

class MyYakku extends StatelessWidget {
  const MyYakku({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingScreen();
  }
}
