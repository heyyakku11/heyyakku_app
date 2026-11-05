import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/presentation/dashboard.dart';
import 'package:yakku/presentation/screens/answer_poll_screen.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_chat_screen.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_list_screen.dart';
import 'package:yakku/presentation/screens/onboarding_screen.dart';
import 'package:yakku/presentation/screens/otp_screen.dart';
import 'package:yakku/presentation/screens/poll_flow_args.dart';
import 'package:yakku/presentation/screens/poll_results_screen.dart';
import 'package:yakku/presentation/screens/sign_up_screen.dart';
import 'package:yakku/presentation/screens/shared_poll_screen.dart';

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
        final onOtp = state.matchedLocation == AppRoutes.otp;
        final onSignUp =
            state.matchedLocation == AppRoutes.signUp || onOtp;

        if (!canEnter && !onOnboarding && !onSignUp) {
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
        if ((canEnter && onOnboarding) ||
            (authController.isLoggedIn && onSignUp)) {
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
          path: AppRoutes.signUp,
          name: AppRoutes.signUpName,
          // Sign-up slides in over onboarding as it replaces it.
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const SignUpScreen(),
            transitionDuration: const Duration(milliseconds: 380),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.12, 0),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
          ),
        ),
        GoRoute(
          path: AppRoutes.otp,
          name: AppRoutes.otpName,
          builder: (context, state) {
            final phone = state.extra;
            if (phone is! String || phone.length != 10) {
              return const SignUpScreen();
            }
            return OtpScreen(phoneDigits: phone);
          },
        ),
        GoRoute(
          path: AppRoutes.main,
          name: AppRoutes.mainName,
          builder: (context, state) => const Dashboard(),
        ),
        GoRoute(
          path: AppRoutes.askBack,
          name: AppRoutes.askBackName,
          builder: (context, state) => const AskBackListScreen(),
        ),
        GoRoute(
          path: AppRoutes.askBackChat,
          name: AppRoutes.askBackChatName,
          builder: (context, state) => AskBackChatScreen(
            key: ValueKey(state.pathParameters['conversationId']),
            conversationId: state.pathParameters['conversationId'] ?? '',
          ),
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
      ],
    );
  }
}
