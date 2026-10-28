import 'dart:math' as math;
import 'package:yakku/core/theme/yakku_palette.dart';

import 'package:flutter/material.dart';

/// Tilted pink card previewing the question friends will see: "NAME asked".
class AskPreviewCard extends StatelessWidget {
  const AskPreviewCard({
    super.key,
    required this.question,
    this.optionCount = 3,
    this.cardColor = _cardPink,
    this.textColor = YakkuPalette.white,
  });

  final String question;
  final int optionCount;

  /// Card background and the colour of its text and answer bars.
  final Color cardColor;
  final Color textColor;

  static const _cardPink = YakkuPalette.cardPink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Transform.rotate(
        angle: -4 * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: cardColor.withValues(alpha: 0.35),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Yakku.',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < optionCount; i++) ...[
                  if (i > 0) const SizedBox(height: 5),
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
