import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/presentation/screens/home/fun_cards_screen.dart';
import 'package:yakku/presentation/screens/home/widgets/sub_mirror_check_card.dart';

/// The "Just for fun" row on the home feed: a few cards and a "See all" tile
/// that opens the full list. Hidden when there are no cards left to make.
class JustForFunSection extends StatelessWidget {
  const JustForFunSection({super.key, required this.cards});

  /// Active cards the caller has not made yet.
  final List<MirrorCheck> cards;

  /// Most cards shown on the home feed; the rest are behind "See all".
  static const maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final visible = cards.take(maxVisible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTag('Just for fun'),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.72;

            return SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: visible.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index == visible.length) {
                    return SizedBox(
                      width: 110,
                      child: _SeeAllTile(
                        onTap: () => openFunCards(context, cards),
                      ),
                    );
                  }
                  return SizedBox(
                    width: cardWidth,
                    child: SubMirrorCheckCard(
                      check: visible[index],
                      showTitle: false,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SeeAllTile extends StatelessWidget {
  const _SeeAllTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const DashedBorderPainter(color: YakkuPalette.Ink, radius: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: YakkuPalette.Raspberry,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'See all',
                  style: TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 15,
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

/// A dashed rounded border, for the "See all" tile.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
