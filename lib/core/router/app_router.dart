import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/presentation/dashboard.dart';
import 'package:yakku/presentation/screens/answer_poll_screen.dart';
import 'package:yakku/presentation/screens/onboarding_screen.dart';
import 'package:yakku/presentation/screens/poll_flow_args.dart';
import 'package:yakku/presentation/screens/poll_results_screen.dart';
import 'package:yakku/presentation/screens/shared_poll_screen.dart';
import 'package:yakku/presentation/screens/view_poll_screen.dart';

abstract final class AppRouter {
  static GoRouter create(
    AuthController authController, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: authController.canEnterApp
          ? AppRoutes.main
          : AppRoutes.onboarding,
      refreshListenable: authController,
      redirect: (context, state) {
        final canEnter = authController.canEnterApp;
        final onOnboarding = state.matchedLocation == AppRoutes.onboarding;

        if (!canEnter && !onOnboarding) {
          // Keep a shared-poll destination through onboarding / login.
          final shareCode = PollDeepLink.shareCodeFromPath(state.uri);
          if (shareCode == null) return AppRoutes.onboarding;
          return Uri(
            path: AppRoutes.onboarding,
            queryParameters: {
              PollDeepLink.returnToParam: AppRoutes.pollVoteLocation(shareCode),
            },
          ).toString();
        }
        if (canEnter && onOnboarding) {
          return PollDeepLink.safeReturnPath(
                state.uri.queryParameters[PollDeepLink.returnToParam],
              ) ??
              AppRoutes.main;
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
          path: AppRoutes.pollVote,
          name: AppRoutes.pollVoteName,
          builder: (context, state) => SharedPollScreen(
            key: ValueKey(state.pathParameters['shareCode']),
            shareCode: state.pathParameters['shareCode'] ?? '',
          ),
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
            if (extra is PollViewArgs) {
              if (extra.pollId.isEmpty) return const Dashboard();
              return ViewPollScreen(
                pollId: extra.pollId,
                canManage: extra.canManage,
              );
            }
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
