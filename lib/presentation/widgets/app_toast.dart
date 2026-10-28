import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// Short-lived message shown at the top of the screen, replacing snackbars.
///
/// Context-free: it draws into the root navigator's overlay, so it is safe to
/// call after an `await` or after the calling screen has been popped.
abstract final class AppToast {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static OverlayEntry? _entry;
  static Timer? _timer;

  /// Registers the root navigator whose overlay hosts the toast.
  static void attach(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  static void show(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = _navigatorKey?.currentState?.overlay;
    if (overlay == null) return;

    dismiss();
    final entry = OverlayEntry(
      builder: (context) => _ToastView(message: message, onDismiss: dismiss),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.4),
            end: Offset.zero,
          ).animate(curved),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: YakkuPalette.primary,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onDismiss,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: YakkuPalette.white,
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
