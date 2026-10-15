import 'package:flutter/material.dart';

/// Bouncing 👆 shown under an option when the user tries to continue without
/// picking their own answer.
///
/// Place it in a [CompositedTransformFollower] linked to the option it should
/// point at, so it tracks the option through scrolling and keyboard changes.
class PickHintFinger extends StatefulWidget {
  const PickHintFinger({super.key});

  @override
  State<PickHintFinger> createState() => _PickHintFingerState();
}

class _PickHintFingerState extends State<PickHintFinger>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _enter.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _enter,
        child: AnimatedBuilder(
          animation: _bounce,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_bounce.value);
            return Transform.translate(
              offset: Offset(0, 6 - 6 * t),
              child: Transform.scale(scale: 0.85 + 0.25 * t, child: child),
            );
          },
          child: const Text('👆', style: TextStyle(fontSize: 34)),
        ),
      ),
    );
  }
}
