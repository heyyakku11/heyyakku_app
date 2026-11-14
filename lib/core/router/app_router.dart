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
import 'package:yakku/presentation/screens/card_results_screen.dart';
import 'package:yakku/presentation/screens/sign_up_screen.dart';
import 'package:yakku/presentation/screens/shared_poll_screen.dart';

abstract final class AppRouter {
  /// Signed-out start: onboarding the first time, sign-up after that.
  static String _signedOutEntry(AuthController authController) =>
      authController.hasCompletedOnboarding
      ? AppRoutes.signUp
      : AppRoutes.onboarding;

  /// Keeps a shared-poll return path when sending the user to [path].
  static String _withReturn(String path, GoRouterState state) {
    final from = state.uri.queryParameters[PollDeepLink.returnToParam];
    if (from == null || from.isEmpty) return path;
    return Uri(
      path: path,
      queryParameters: {PollDeepLink.returnToParam: from},
    ).toString();
  }

  static GoRouter create(
    AuthController authController, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: authController.canEnterApp
          ? AppRoutes.main
          : _signedOutEntry(authController),
      refreshListenable: authController,
      redirect: (context, state) {
        final canEnter = authController.canEnterApp;
        final seenOnboarding = authController.hasCompletedOnboarding;
        final entry = _signedOutEntry(authController);
        final onOnboarding = state.matchedLocation == AppRoutes.onboarding;
        final onOtp = state.matchedLocation == AppRoutes.otp;
        final onSignUp = state.matchedLocation == AppRoutes.signUp || onOtp;
        if (canEnter && (onOnboarding || onSignUp)) {
          return PollDeepLink.safeReturnPath(
                state.uri.queryParameters[PollDeepLink.returnToParam],
              ) ??
              AppRoutes.main;
        }
        if (!canEnter) {
          // Onboarding is once per install. After the flag is true, sign-up
          // is the signed-out screen, including after logout.
          if (seenOnboarding && onOnboarding) {
            return _withReturn(AppRoutes.signUp, state);
          }
          // First launch stays on onboarding until the user finishes it.
          // OTP stays open so a code already in progress is not dropped.
          if (!seenOnboarding && state.matchedLocation == AppRoutes.signUp) {
            return _withReturn(AppRoutes.onboarding, state);
          }
          if (!onOnboarding && !onSignUp) {
            // Keep a shared-poll destination through onboarding / login.
            final shareCode = PollDeepLink.shareCodeFromPath(state.uri);
            if (shareCode == null) return entry;
            return Uri(
              path: entry,
              queryParameters: {
                PollDeepLink.returnToParam: AppRoutes.pollVoteLocation(
                  shareCode,
                ),
              },
            ).toString();
          }
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
            return CardResultsScreen(
              poll: args.poll,
              selectedOptionId: args.selectedOptionId,
            );
          },
        ),
      ],
    );
  }
}
