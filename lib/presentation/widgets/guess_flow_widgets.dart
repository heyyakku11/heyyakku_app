import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// Shared pieces of the two-step "you guess first, then ask" screens: the
/// personality claim screen and the create-poll claim screen.

/// "1 Your guess ──── 2 Ask now". [step2] is true once the guess is made.
class GuessStepper extends StatelessWidget {
  const GuessStepper({super.key, required this.step2});

  final bool step2;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(number: 1, label: 'Your guess', active: !step2, done: step2),
        Expanded(
          child: Container(
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: step2
                ? YakkuPalette.Ink
                : YakkuPalette.Raspberry.withValues(alpha: 0.2),
          ),
        ),
        _StepDot(number: 2, label: 'Ask now', active: step2, done: false),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
  });

  final int number;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final Color fill = done
        ? YakkuPalette.Ink
        : active
        ? YakkuPalette.Raspberry
        : YakkuPalette.white;
    final Color text = done || active ? YakkuPalette.white : YakkuPalette.Ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: done
              ? const FaIcon(
                  FontAwesomeIcons.check,
                  size: 11,
                  color: YakkuPalette.white,
                )
              : Text(
                  '$number',
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: active ? YakkuPalette.Ink : YakkuPalette.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// The small white pill above the title ("WHO YOU ARE", "YOUR QUESTION").
class GuessTag extends StatelessWidget {
  const GuessTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: YakkuPalette.Raspberry,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// The tilted yellow "You guess first!" sticker. [shake] (0..1) drives a
/// damped rotation in place; run it to point at what is missing.
class GuessSticker extends StatelessWidget {
  const GuessSticker({super.key, required this.text, required this.shake});

  final String text;
  final Animation<double> shake;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shake,
      builder: (context, child) {
        // A damped swing around the sticker's own centre, settling back to
        // its tilt.
        final decay = 1 - Curves.easeOut.transform(shake.value);
        final wave = math.sin(shake.value * math.pi * 6) * decay;
        return Transform.rotate(angle: wave * 0.16, child: child);
      },
      child: Transform.rotate(
        angle: -0.07,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: YakkuPalette.Gold,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: YakkuPalette.Ink, width: 1.5),
            boxShadow: const [
              BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 3)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Pacifico',
                color: YakkuPalette.Ink,
                fontSize: 26,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A hand-drawn style arrow: it leaves the sticker, curves over and points
/// down at the choices.
class GuessArrow extends StatelessWidget {
  const GuessArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(40, 34),
      painter: _CurvedArrowPainter(YakkuPalette.Ink),
    );
  }
}

class _CurvedArrowPainter extends CustomPainter {
  const _CurvedArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Designed on a 40 x 34 canvas and scaled to the actual size.
    final sx = size.width / 40;
    final sy = size.height / 34;
    Offset o(double x, double y) => Offset(x * sx, y * sy);

    final shaft = Path()
      ..moveTo(o(3, 8).dx, o(3, 8).dy)
      ..cubicTo(
        o(14, 2).dx,
        o(14, 2).dy,
        o(30, 3).dx,
        o(30, 3).dy,
        o(33, 24).dx,
        o(33, 24).dy,
      );
    canvas.drawPath(shaft, paint);

    // Open arrowhead at the tip.
    final head = Path()
      ..moveTo(o(26, 18).dx, o(26, 18).dy)
      ..lineTo(o(33, 25).dx, o(33, 25).dy)
      ..lineTo(o(38, 16).dx, o(38, 16).dy);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_CurvedArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// "🔒 Only you see your guess."
class GuessPrivacyNote extends StatelessWidget {
  const GuessPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: YakkuPalette.Ink),
          SizedBox(width: 6),
          Text(
            'Only you see your guess.',
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Ask now" button. While [enabled] is false it looks faded and a tap
/// calls [onDisabledTap] (the screens use it to shake the sticker).
class GuessAskButton extends StatelessWidget {
  const GuessAskButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onPressed,
    required this.onDisabledTap,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;
  final VoidCallback onDisabledTap;

  @override
  Widget build(BuildContext context) {
    // A disabled button swallows taps, so listen above it instead.
    return GestureDetector(
      onTap: enabled ? null : onDisabledTap,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(
        absorbing: !enabled,
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: YakkuPalette.Raspberry,
              disabledBackgroundColor: YakkuPalette.Raspberry.withValues(
                alpha: 0.18,
              ),
              foregroundColor: YakkuPalette.white,
              disabledForegroundColor: YakkuPalette.Raspberry.withValues(
                alpha: 0.45,
              ),
              shape: const StadiumBorder(),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: YakkuPalette.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ios_share_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Ask now',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
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

/// Paints a dashed rounded-rectangle outline (for locked or empty slots).
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
          Radius.circular(radius),
        ),
      );

    const dashWidth = 5.0;
    const dashSpace = 3.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// One of the user's own options: white pill with an ink border and a hard
/// shadow; ink fill with a check when picked.
class GuessAnswerRow extends StatelessWidget {
  const GuessAnswerRow({
    super.key,
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Option $letter: $text',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: selected ? YakkuPalette.Ink : YakkuPalette.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: YakkuPalette.Ink, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: selected ? YakkuPalette.Raspberry : YakkuPalette.Ink,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? YakkuPalette.Raspberry
                      : YakkuPalette.pinkWash,
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: YakkuPalette.white,
                      )
                    : Text(
                        letter,
                        style: const TextStyle(
                          color: YakkuPalette.Raspberry,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: selected ? YakkuPalette.white : YakkuPalette.Ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The locked "D" slot: friends can add their own answer once the poll is
/// live, so it is not selectable.
class GuessLockedSlot extends StatelessWidget {
  const GuessLockedSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(
        color: YakkuPalette.Raspberry.withValues(alpha: 0.7),
        radius: 14,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: YakkuPalette.Raspberry.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: YakkuPalette.white,
              ),
              child: const Text(
                'D',
                style: TextStyle(
                  color: YakkuPalette.Raspberry,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Friends add their own',
                style: TextStyle(
                  color: YakkuPalette.Raspberry,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: YakkuPalette.Raspberry,
            ),
          ],
        ),
      ),
    );
  }
}
