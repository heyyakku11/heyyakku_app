import 'package:flutter/material.dart';

/// What the Friends tab shows while Home is loading: grey blocks where the content will land (a tag, a wide bar,
/// the featured card, a section tag and two cards), so the page does not jump when the data arrives.
/// The blocks pulse gently; with the system's "reduce motion" setting on they stay still.
class HomeFeedSkeleton extends StatefulWidget {
  const HomeFeedSkeleton({super.key});

  @override
  State<HomeFeedSkeleton> createState() => _HomeFeedSkeletonState();
}

class _HomeFeedSkeletonState extends State<HomeFeedSkeleton>
    with SingleTickerProviderStateMixin {
  static const _block = Color(0xFFF1E6EA);

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

  Widget _box({double? width, required double height, required double radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _block,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
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
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _box(width: 104, height: 38, radius: 14),
                ),
                const SizedBox(height: 12),
                _box(height: 52, radius: 16),
                const SizedBox(height: 12),
                _box(height: 246, radius: 30),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _box(width: 130, height: 22, radius: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _box(height: 150, radius: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: _box(height: 150, radius: 24)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
