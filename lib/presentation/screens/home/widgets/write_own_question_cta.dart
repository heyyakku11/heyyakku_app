import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/screens/create/create_screen.dart';

/// Dashed "Write your own question" button shown under the suggested questions.
class WriteOwnQuestionCta extends StatelessWidget {
  const WriteOwnQuestionCta({super.key, this.onTap});

  /// Defaults to opening the create-poll sheet with an empty draft.
  final VoidCallback? onTap;

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedBorderPainter(
        color: YakkuPalette.primaryBright,
        radius: _radius,
      ),
      child: Material(
        color: YakkuPalette.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(_radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius),
          onTap: onTap ?? () => showCreatePollSheet(context),
          child: const SizedBox(
            height: 62,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: YakkuPalette.primary, size: 22),
                SizedBox(width: 10),
                Text(
                  'Write your own question',
                  style: TextStyle(
                    color: YakkuPalette.primary,
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

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 6).clamp(0, metric.length)),
          paint,
        );
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
