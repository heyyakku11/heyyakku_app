import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// The shareable card for a check or poll: what a friend sees before
/// answering. The option texts are blurred so the owner's pick and the
/// answers stay a surprise until the friend opens the link.
class CheckShareCard extends StatelessWidget {
  const CheckShareCard({
    super.key,
    required this.title,
    required this.question,
    required this.options,
    this.width = 300,
    this.tilt = -0.05,
  });

  /// Small heading such as "Mirror Check". Hidden when it repeats the question.
  final String title;
  final String question;

  /// The answer labels, shown blurred.
  final List<String> options;
  final double width;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final showTitle =
        title.trim().isNotEmpty &&
        title.trim().toLowerCase() != question.trim().toLowerCase();
    final headline = question.trim().isNotEmpty ? question.trim() : title;

    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: YakkuPalette.pinkTint,
          borderRadius: BorderRadius.circular(24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text.rich(
                    TextSpan(
                      text: 'Yakku',
                      style: TextStyle(
                        color: YakkuPalette.Ink,
                        fontSize: 20,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                      children: [
                        TextSpan(
                          text: '.',
                          style: TextStyle(color: YakkuPalette.Raspberry),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const _NoFiltersTag(),
              ],
            ),
            const SizedBox(height: 14),
            if (showTitle) ...[
              Text(
                title,
                style: const TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 24,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              headline,
              style: TextStyle(
                color: YakkuPalette.Ink,
                fontSize: showTitle ? 15 : 22,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: showTitle ? -0.2 : -0.7,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < options.length; i++) ...[
              _BlurredOption(
                letter: String.fromCharCode(65 + i),
                text: options[i],
              ),
              const SizedBox(height: 8),
            ],
            _FriendsAddOption(letter: String.fromCharCode(65 + options.length)),
            const SizedBox(height: 14),
            Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: YakkuPalette.Ink,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: YakkuPalette.Raspberry.withValues(alpha: 0.8),
                    offset: const Offset(0, 2.5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.link,
                    size: 13,
                    color: YakkuPalette.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Answer anonymously',
                    style: TextStyle(
                      color: YakkuPalette.white,
                      fontSize: 15,
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

/// The little "No filters. Just truth." sticker in the card's corner.
class _NoFiltersTag extends StatelessWidget {
  const _NoFiltersTag();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.07,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: YakkuPalette.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: YakkuPalette.Ink, width: 1),
          boxShadow: const [
            BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 2)),
          ],
        ),
        child: const Text(
          'No filters.\nJust truth.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Pacifico',
            color: YakkuPalette.Raspberry,
            fontSize: 11,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

class _BlurredOption extends StatelessWidget {
  const _BlurredOption({required this.letter, required this.text});

  final String letter;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 12, 8),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: YakkuPalette.pinkWash,
            ),
            child: Text(
              letter,
              style: const TextStyle(
                color: YakkuPalette.Raspberry,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: 3,
                sigmaY: 3,
                tileMode: TileMode.decal,
              ),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsAddOption extends StatelessWidget {
  const _FriendsAddOption({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 12, 8),
      decoration: BoxDecoration(
        color: YakkuPalette.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: YakkuPalette.white,
            ),
            child: Text(
              letter,
              style: const TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Friends add their own',
              style: TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.add_rounded, size: 16, color: YakkuPalette.Raspberry),
        ],
      ),
    );
  }
}

/// The Instagram Story version: the card centred on a pink 9:16 canvas, sized
/// 360x640 so StoryImageService can render it.
class CheckStoryCard extends StatelessWidget {
  const CheckStoryCard({
    super.key,
    required this.title,
    required this.question,
    required this.options,
  });

  final String title;
  final String question;
  final List<String> options;

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
            CheckShareCard(
              title: title,
              question: question,
              options: options,
              width: 300,
            ),
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
