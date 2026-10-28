import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/utils/hex_color.dart';

/// Shown instead of results while a card is under its vote limit: the card
/// itself, how many votes it has, and a way to send it to more people.
class ResultsLockedView extends StatelessWidget {
  const ResultsLockedView({
    super.key,
    required this.question,
    required this.options,
    required this.progress,
    required this.minVotes,
    required this.onShareAgain,
    this.label = 'YOUR CARD · LIVE',
    this.tag,
    this.backgroundColor,
  });

  final String question;

  /// Option labels shown on the card (the first four are used).
  final List<String> options;

  /// Votes received so far, not counting the owner's own answer.
  final int progress;
  final int minVotes;
  final VoidCallback onShareAgain;
  final String label;

  /// Small caption above the question, e.g. "TRUST CHECK".
  final String? tag;

  /// Hex colour of the card, when it has one.
  final String? backgroundColor;

  static const _ink = YakkuPalette.textPrimary;
  static const _muted = YakkuPalette.textSecondary;
  static const _mint = YakkuPalette.mint;

  @override
  Widget build(BuildContext context) {
    final cardColor = parseHexColor(backgroundColor ?? '', fallback: _mint);
    final filled = progress.clamp(0, minVotes);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 18),
          _LockedCard(
            question: question,
            options: options.take(4).toList(growable: false),
            tag: tag,
            color: cardColor,
          ),
          const SizedBox(height: 28),
          DecoratedBox(
            decoration: BoxDecoration(
              color: YakkuPalette.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: YakkuPalette.roseBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$filled of $minVotes votes',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Result unlocks at $minVotes',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < minVotes; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: i < filled
                                  ? YakkuPalette.primary
                                  : YakkuPalette.blushFill,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: onShareAgain,
                      style: FilledButton.styleFrom(
                        backgroundColor: YakkuPalette.primary,
                        foregroundColor: YakkuPalette.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Share again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard({
    required this.question,
    required this.options,
    required this.color,
    this.tag,
  });

  final String question;
  final List<String> options;
  final Color color;
  final String? tag;

  static const _ink = YakkuPalette.textPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Transform.rotate(
        angle: -2 * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _ink, width: 2),
            boxShadow: const [BoxShadow(color: _ink, offset: Offset(0, 6))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yakku.',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (tag != null && tag!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    tag!.toUpperCase(),
                    style: const TextStyle(
                      color: YakkuPalette.successGreen,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  question,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < options.length; i++) ...[
                  Container(
                    height: 28,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _ink.withAlpha(10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Text(
                        options[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (i < options.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
