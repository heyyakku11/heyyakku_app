import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/presentation/screens/home/fun_cards_screen.dart';
import 'package:yakku/presentation/screens/home/widgets/sub_mirror_check_card.dart';

/// One row of fun cards on the home feed: the cards of a single type under that type's name, and a
/// "See all" tile that opens that type's full list. Hidden when there are no cards left to make.
class JustForFunSection extends StatelessWidget {
  const JustForFunSection({
    super.key,
    required this.cards,
    this.title = defaultTitle,
    this.typeId,
    int? totalCount,
  }) : totalCount = totalCount ?? cards.length;

  static const defaultTitle = 'Just for fun';

  /// The card type shown as the section heading.
  final String title;

  /// The type's id, which the "See all" list is loaded by; null means no such list.
  final String? typeId;

  /// Cards of this type shown in the row (a preview of at most 4).
  final List<MirrorCheck> cards;

  /// All cards of this type the caller can still make; "See all" appears when it is more than the row shows.
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final visible = cards;
    final hasMore = typeId != null && totalCount > visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTag(title),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.72;

            return SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: visible.length + (hasMore ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index == visible.length) {
                    return SizedBox(
                      width: 110,
                      child: _SeeAllTile(
                        onTap: () => openFunCards(
                          context,
                          cards,
                          title: title,
                          typeId: typeId!,
                        ),
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
