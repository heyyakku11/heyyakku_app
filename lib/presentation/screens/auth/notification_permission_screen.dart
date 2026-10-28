import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_button.dart';

/// Full-screen "Don't miss your reveal" step shown right after OTP login.
/// Asks for OS notification permission and registers the device. Pops `true`
/// when notifications were enabled, `false` when skipped.
class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  /// Pushes the screen only if this user still has to be asked.
  static Future<void> showIfNeeded(BuildContext context) async {
    final scope = AppScope.of(context);
    final shouldPrompt = await scope.deviceRegistration
        .shouldPromptForPermission();
    if (!context.mounted) return;
    if (!shouldPrompt) {
      scope.deviceRegistration.syncDeviceInBackground();
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const NotificationPermissionScreen(),
      ),
    );
  }

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  bool _busy = false;

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _slot(double start, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  );

  Future<void> _choose({required bool allow}) async {
    if (_busy) return;
    setState(() => _busy = true);

    final scope = AppScope.of(context);
    final registration = scope.deviceRegistration;
    var granted = false;
    try {
      if (allow) {
        granted = await registration.applyAllowChoice();
      } else {
        await registration.applySkipChoice();
      }
    } catch (_) {
      // The choice is stored locally and the device is updated in the
      // background; a failed sync must not block the user.
    }
    if (mounted) Navigator.of(context).pop(granted);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: YakkuPalette.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                const Spacer(),
                _Reveal(
                  animation: _slot(0.0, 0.5),
                  fromTop: true,
                  child: const _PushPreview(
                    message:
                        'Your result is ready. Tap to see what your friends said.',
                  ),
                ),
                const SizedBox(height: 10),
                _Reveal(
                  animation: _slot(0.25, 0.75),
                  fromTop: true,
                  child: const _SecondaryPreview(
                    text: 'Someone added their own option to your card.',
                  ),
                ),
                const Spacer(flex: 2),
                _Reveal(
                  animation: _slot(0.4, 1.0),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          "Don't miss your reveal",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: YakkuPalette.textPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          "We'll tell you when votes, reasons or your result "
                          'arrive. Never more than 3 a day, and never at night.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: YakkuPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                AppButton(
                  label: _busy ? 'Please wait...' : 'Turn on notifications',
                  onPressed: _busy ? null : () => _choose(allow: true),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _busy ? null : () => _choose(allow: false),
                  child: const Text(
                    'Not now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: YakkuPalette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.child,
    this.fromTop = false,
  });

  final Animation<double> animation;
  final Widget child;
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, fromTop ? -0.25 : 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Mock of the OS push banner.
class _PushPreview extends StatelessWidget {
  const _PushPreview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: YakkuPalette.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: YakkuPalette.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Y.',
              style: TextStyle(
                color: YakkuPalette.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Yakku',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: YakkuPalette.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' · now',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: YakkuPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: YakkuPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Second, quieter banner stacked under the first.
class _SecondaryPreview extends StatelessWidget {
  const _SecondaryPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: YakkuPalette.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: YakkuPalette.hairline),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: YakkuPalette.textSecondary,
        ),
      ),
    );
  }
}
