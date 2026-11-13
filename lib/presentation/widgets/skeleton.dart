import 'package:flutter/material.dart';

/// Pale rose of the grey blocks that stand in for content while a screen loads.
const kSkeletonColor = Color(0xFFF1E6EA);

/// One placeholder block. Put several inside a [SkeletonPulse] so they pulse together.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
    this.circle = false,
  });

  /// A round block, for avatars.
  const SkeletonBox.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = 0,
      circle = true;

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: kSkeletonColor,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Pulses its child gently while content loads, and cannot be tapped or scrolled. With the system's "reduce
/// motion" setting on it stays still. A screen reader hears "Loading".
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.55,
              end: 1,
            ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
