import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// Branded splash shown over the app right after the native splash screen.
/// The letters of "Yakku" pop in one by one, the gold dot drops and bounces,
/// then the splash fades to reveal [child]. Plays once.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});

  final Widget? child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 3300);

  late final AnimationController _controller;
  late final Animation<double> _exit;

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _done = true);
        }
      })
      ..forward();
    _exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(3070 / 3300, 1.0, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child ?? const SizedBox.shrink();
    if (_done) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return IgnorePointer(
              ignoring: _exit.value > 0.5,
              child: Opacity(
                opacity: 1 - _exit.value,
                child: ColoredBox(
                  color: YakkuPalette.primary,
                  child: Center(child: _Wordmark(progress: _controller)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.progress});

  final Animation<double> progress;

  static const _letters = ['Y', 'a', 'k', 'k', 'u'];
  static const _style = TextStyle(
    color: YakkuPalette.white,
    fontSize: 80.64,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.88,
    decoration: TextDecoration.none,
  );

  // Phase fractions are of the 2.3s intro; _k rescales them to the full timeline
  // (intro + 1s hold + fade).
  static const _k = 2300 / 3300;

  // Letters stagger across 0.05-0.55 of the intro, each lasting 0.2.
  static const _letterStart = 0.05;
  static const _letterStep = 0.075;
  static const _letterSpan = 0.2;

  // Dot drops after the last letter lands.
  static const _dotStart = 0.5;
  static const _dotEnd = 0.85;
  static const _dropHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    final dotDrop = CurvedAnimation(
      parent: progress,
      curve: const Interval(
        _dotStart * _k,
        _dotEnd * _k,
        curve: Curves.bounceOut,
      ),
    );
    final dotAppear = CurvedAnimation(
      parent: progress,
      curve: const Interval(_dotStart * _k, (_dotStart + 0.05) * _k),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < _letters.length; i++)
          _PopLetter(
            letter: _letters[i],
            style: _style,
            animation: CurvedAnimation(
              parent: progress,
              curve: Interval(
                (_letterStart + i * _letterStep) * _k,
                (_letterStart + i * _letterStep + _letterSpan) * _k,
                curve: Curves.easeOutBack,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 4.3, bottom: 6),
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, child) {
              return Opacity(
                opacity: dotAppear.value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -_dropHeight * (1 - dotDrop.value)),
                  child: child,
                ),
              );
            },
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: YakkuPalette.Gold,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 15.84, height: 15.84),
            ),
          ),
        ),
      ],
    );
  }
}

class _PopLetter extends StatelessWidget {
  const _PopLetter({
    required this.letter,
    required this.style,
    required this.animation,
  });

  final String letter;
  final TextStyle style;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: Transform.scale(
              scale: t,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: Text(letter, style: style),
    );
  }
}
