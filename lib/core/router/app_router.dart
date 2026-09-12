import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/presentation/dashboard.dart';
import 'package:yakku/presentation/screens/onboarding_screen.dart';

abstract final class AppRouter {
  static GoRouter create(AuthController authController) {
    return GoRouter(
      initialLocation: authController.isLoggedIn
          ? AppRoutes.main
          : AppRoutes.onboarding,
      refreshListenable: authController,
      redirect: (context, state) {
        final loggedIn = authController.isLoggedIn;
        final onOnboarding = state.matchedLocation == AppRoutes.onboarding;

        if (!loggedIn && !onOnboarding) {
          return AppRoutes.onboarding;
        }
        if (loggedIn && onOnboarding) {
          return AppRoutes.main;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          name: AppRoutes.onboardingName,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.main,
          name: AppRoutes.mainName,
          builder: (context, state) => const Dashboard(),
        ),
      ],
    );
  }
}
