import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/presentation/dashboard.dart';
import 'package:yakku/presentation/screens/answer_poll_screen.dart';
import 'package:yakku/presentation/screens/onboarding_screen.dart';
import 'package:yakku/presentation/screens/poll_flow_args.dart';
import 'package:yakku/presentation/screens/poll_results_screen.dart';
import 'package:yakku/presentation/screens/view_poll_screen.dart';

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
        final location = state.matchedLocation;
        final isPollFlow =
            location == AppRoutes.pollAnswer ||
            location == AppRoutes.pollResults ||
            location == AppRoutes.pollView;

        if (!loggedIn && !onOnboarding) {
          return AppRoutes.onboarding;
        }
        if (loggedIn && onOnboarding) {
          return AppRoutes.main;
        }
        if (!loggedIn && isPollFlow) {
          return AppRoutes.onboarding;
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
        GoRoute(
          path: AppRoutes.pollAnswer,
          name: AppRoutes.pollAnswerName,
          builder: (context, state) {
            final args = state.extra;
            if (args is! AnswerPollArgs) {
              return const Dashboard();
            }
            return AnswerPollScreen(poll: args.poll);
          },
        ),
        GoRoute(
          path: AppRoutes.pollResults,
          name: AppRoutes.pollResultsName,
          builder: (context, state) {
            final args = state.extra;
            if (args is! PollResultsArgs) {
              return const Dashboard();
            }
            return PollResultsScreen(
              poll: args.poll,
              selectedOptionId: args.selectedOptionId,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.pollView,
          name: AppRoutes.pollViewName,
          builder: (context, state) {
            final extra = state.extra;
            final pollId = extra is String ? extra : null;
            if (pollId == null || pollId.isEmpty) {
              return const Dashboard();
            }
            return ViewPollScreen(pollId: pollId);
          },
        ),
      ],
    );
  }
}
