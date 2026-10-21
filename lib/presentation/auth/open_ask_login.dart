import 'package:flutter/material.dart';
import 'package:yakku/presentation/screens/auth/ask_login_screen.dart';

/// Full-screen "Who's asking?" login → 6-digit code flow, shown when a guest
/// tries to create a poll. Resolves to true once the user is logged in.
///
/// The bottom-sheet flow (`openMobileLogin`) is still used everywhere else.
Future<bool> openAskLogin(
  BuildContext context, {
  required String question,
  int optionCount = 3,
}) async {
  final done = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) =>
          AskLoginScreen(question: question, optionCount: optionCount),
    ),
  );
  return done ?? false;
}
