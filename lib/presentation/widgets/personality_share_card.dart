import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// The shareable personality card: what a friend sees before answering. The
/// traits are blurred so nothing about the owner's guess leaks.
class PersonalityShareCard extends StatelessWidget {
  const PersonalityShareCard({
    super.key,
    required this.traits,
    this.width = 300,
    this.tilt = -0.06,
  });

  /// Trait names shown (blurred) as chips.
  final List<String> traits;
  final double width;

  /// Rotation in radians; the card sits slightly tilted.
  final double tilt;

  static const _placeholders = [
    'good listener',
    'doesn’t judge',
    'keeps secrets',
    'honest',
    'encouraging',
    'gives good advice',
    'practical',
    'calm',
    'funny',
    'patient',
  ];

  @override
  Widget build(BuildContext context) {
    final names = traits.isEmpty ? _placeholders : traits;
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: YakkuPalette.Raspberry,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: YakkuPalette.Ink, width: 1.5),
          boxShadow: const [
            BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Yakku.',
                  style: TextStyle(
                    color: YakkuPalette.white,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  'WHO YOU ARE',
                  style: TextStyle(
                    color: YakkuPalette.white.withValues(alpha: 0.8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Describe me in 3 words',
              style: TextStyle(
                color: YakkuPalette.white,
                fontSize: 30,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 16),
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: 3.5,
                sigmaY: 3.5,
                tileMode: TileMode.decal,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final name in names) _BlurChip(label: name)],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: YakkuPalette.Ink,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: YakkuPalette.white.withValues(alpha: 0.75),
                    offset: const Offset(0, 2.5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.link,
                    size: 14,
                    color: YakkuPalette.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Answer anonymously',
                    style: TextStyle(
                      color: YakkuPalette.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurChip extends StatelessWidget {
  const _BlurChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: YakkuPalette.Ink, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// The Instagram Story version: the same card centred on a pink 9:16 canvas.
/// Sized 360x640 so StoryImageService can render it.
class PersonalityStoryCard extends StatelessWidget {
  const PersonalityStoryCard({super.key, required this.traits});

  final List<String> traits;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 640,
      child: ColoredBox(
        color: YakkuPalette.pinkTintSoft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PersonalityShareCard(traits: traits, width: 300),
            const SizedBox(height: 36),
            const Text(
              'Tap the link to answer anonymously',
              style: TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
