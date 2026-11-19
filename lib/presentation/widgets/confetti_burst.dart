import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// A one-shot party-popper: confetti shoots up and inwards from both bottom corners, then tumbles down and fades.
/// It fills its parent, ignores touches, and plays once when it first appears. With animations turned off in the
/// system settings it draws nothing.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.colors,
    this.pieces = 90,
    this.duration = const Duration(milliseconds: 3200),
    this.seed,
  });

  /// Colours of the confetti. Defaults to the Yakku brand mix.
  final List<Color>? colors;

  /// How many pieces are shot in total, split between the two corners.
  final int pieces;
  final Duration duration;

  /// Fixes the random layout (for tests); null gives a new one each time.
  final int? seed;

  static const _defaultColors = [
    YakkuPalette.primary,
    YakkuPalette.Gold,
    YakkuPalette.Blush,
    YakkuPalette.skyBlue,
    YakkuPalette.mintBright,
    YakkuPalette.violetTint,
    YakkuPalette.peach,
  ];

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = math.Random(widget.seed);
    final colors = widget.colors ?? ConfettiBurst._defaultColors;
    _pieces = [
      for (var i = 0; i < widget.pieces; i++)
        _Piece.random(
          random,
          fromLeft: i.isEven,
          color: colors[i % colors.length],
        ),
    ];
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_pieces, _controller.value),
          ),
        ),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.fromLeft,
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.phase,
    required this.round,
    required this.delay,
    required this.color,
  });

  factory _Piece.random(
    math.Random random, {
    required bool fromLeft,
    required Color color,
  }) {
    // Shot up and slightly inwards: 55-85 degrees above the horizontal.
    final degrees = 55 + random.nextDouble() * 30;
    return _Piece(
      fromLeft: fromLeft,
      angle: degrees * math.pi / 180,
      speed: 0.9 + random.nextDouble() * 0.8,
      size: 6 + random.nextDouble() * 6,
      spin: (random.nextDouble() - 0.5) * 14,
      phase: random.nextDouble() * math.pi * 2,
      round: random.nextDouble() < 0.3,
      delay: random.nextDouble() * 0.12,
      color: color,
    );
  }

  final bool fromLeft;
  final double angle;

  /// Launch speed, in screen heights per second of animation time.
  final double speed;
  final double size;
  final double spin;
  final double phase;
  final bool round;

  /// Share of the animation to wait before this piece pops.
  final double delay;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;

  /// 0 to 1 over the whole animation.
  final double t;

  static const _gravity = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final piece in pieces) {
      final local = ((t - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      // Time in "seconds" of the throw: the whole animation is one unit.
      final time = local * 1.9;
      final dir = piece.fromLeft ? 1.0 : -1.0;
      final vx = math.cos(piece.angle) * piece.speed * dir;
      final vy = -math.sin(piece.angle) * piece.speed;

      final x0 = piece.fromLeft ? 0.0 : size.width;
      final y0 = size.height * 0.95;
      final x = x0 + vx * time * size.height * 0.55;
      final y = y0 + (vy * time + 0.5 * _gravity * time * time) * size.height;
      // A gentle side-to-side flutter as it falls.
      final sway = math.sin(time * 5 + piece.phase) * 6 * local;

      // Fade over the last quarter.
      final opacity = local < 0.75 ? 1.0 : (1 - local) / 0.25;
      if (opacity <= 0 || y > size.height * 1.1) continue;

      paint.color = piece.color.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate(piece.spin * time + piece.phase);
      if (piece.round) {
        canvas.drawCircle(Offset.zero, piece.size * 0.4, paint);
      } else {
        // Flip the rectangle's height to fake it tumbling in 3D.
        final flip = math.cos(time * 9 + piece.phase).abs().clamp(0.25, 1.0);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.55 * flip,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}
