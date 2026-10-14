import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/auth/guest_session_service.dart';
import 'package:yakku/core/auth/guest_token_store.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/background/background_job.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';

/// Reacts to [BackgroundApiWorker] terminal results that need UI or session side effects.
class BackgroundJobEffects extends StatefulWidget {
  const BackgroundJobEffects({
    super.key,
    required this.worker,
    required this.authController,
    required this.guestTokenStore,
    required this.navigatorKey,
    required this.child,
  });

  final BackgroundApiWorker worker;
  final AuthController authController;
  final GuestTokenStore guestTokenStore;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget? child;

  @override
  State<BackgroundJobEffects> createState() => _BackgroundJobEffectsState();
}

class _BackgroundJobEffectsState extends State<BackgroundJobEffects> {
  StreamSubscription<BackgroundJobResult>? _subscription;
  bool _handlingGuestFailure = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.worker.results.listen(_onResult);
  }

  @override
  void didUpdateWidget(BackgroundJobEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worker != widget.worker) {
      unawaited(_subscription?.cancel());
      _subscription = widget.worker.results.listen(_onResult);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }

  Future<void> _onResult(BackgroundJobResult result) async {
    if (result.type != GuestSessionService.jobType) return;
    if (result.success) return;
    if (_handlingGuestFailure) return;
    if (!widget.authController.hasEnteredAsGuest) return;

    _handlingGuestFailure = true;
    try {
      final navContext = widget.navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        await showAppAlert(
          navContext,
          title: 'Could not start guest session',
          message:
              'We could not create your anonymous profile. Please try again.',
        );
      }

      await widget.guestTokenStore.clear();
      await widget.authController.revokeGuestEntry();
    } finally {
      _handlingGuestFailure = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}
