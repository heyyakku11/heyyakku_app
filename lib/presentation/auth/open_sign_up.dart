import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/router/app_routes.dart';

/// Sends a signed-out user to the sign-up screen. This replaces the current
/// stack, so sign-up has nothing to go back to.
void openSignUp(BuildContext context) => context.go(AppRoutes.signUp);
