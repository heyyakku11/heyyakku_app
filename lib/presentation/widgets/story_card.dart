import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// 9:16 Instagram Story image: the tilted pink Yakku card (same look as the
/// preview on the share screen) on a soft pink backdrop, with the answer
/// options readable. Laid out at a fixed logical [size]; the question shrinks
/// to fit so long text never overflows.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.question, this.options = const []});

  final String question;
  final List<String> options;

  /// Logical size; exported at 3x for 1080x1920.
  static const Size size = Size(360, 640);

  static const int maxOptions = 4;
  static const int _questionMaxLines = 4;
  static const double _questionMaxFontSize = 30;
  static const double _questionMinFontSize = 16;

  static const double _horizontalPadding = 32;
  static const double _cardPadding = 18;

  static const _cardPink = YakkuPalette.cardPink;

  @override
  Widget build(BuildContext context) {
    final shown = options
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .take(maxOptions)
        .toList();
    return SizedBox.fromSize(
      size: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              YakkuPalette.pinkMist,
              YakkuPalette.pinkWash,
              YakkuPalette.avatarPink,
            ],
          ),
        ),
        // Instagram covers the top and bottom of a story with its own UI, so
        // the card stays in the middle band.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            90,
            _horizontalPadding,
            90,
          ),
          // scaleDown keeps worst-case content (4 options, long question)
          // inside the safe area instead of overflowing it.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: size.width - _horizontalPadding * 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: 4 * math.pi / 180,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _cardPink,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: _cardPink.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _cardPadding,
                          _cardPadding,
                          _cardPadding,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Yakku',
                                    style: TextStyle(
                                      color: YakkuPalette.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '.',
                                    style: TextStyle(
                                      color: YakkuPalette.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FittedQuestion(question.trim()),
                            const SizedBox(height: 18),
                            for (final option in shown) ...[
                              _OptionPill(option),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 6),
                            const Text(
                              "Tap to answer. They won't know it was you.",
                              style: TextStyle(
                                color: YakkuPalette.white,
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  // Placeholder spot for the Link sticker the user adds in
                  // Instagram (the link is copied to the clipboard).
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_link,
                        color: YakkuPalette.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Add URL Sticker',
                        style: TextStyle(
                          color: YakkuPalette.primary,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The question at the largest font size that fits [StoryCard._questionMaxLines]
/// lines; at the minimum size it is cut off with an ellipsis instead of
/// overflowing.
class _FittedQuestion extends StatelessWidget {
  const _FittedQuestion(this.text);

  final String text;

  TextStyle _style(double fontSize) => TextStyle(
    color: YakkuPalette.white,
    fontSize: fontSize,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:
          StoryCard.size.width -
          StoryCard._horizontalPadding * 2 -
          StoryCard._cardPadding * 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          var fontSize = StoryCard._questionMaxFontSize;
          while (fontSize > StoryCard._questionMinFontSize) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: _style(fontSize)),
              textDirection: TextDirection.ltr,
              textScaler: TextScaler.noScaling,
              maxLines: StoryCard._questionMaxLines,
            )..layout(maxWidth: constraints.maxWidth);
            final fits = !painter.didExceedMaxLines;
            painter.dispose();
            if (fits) break;
            fontSize -= 1;
          }
          return Text(
            text,
            maxLines: StoryCard._questionMaxLines,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            style: _style(fontSize),
          );
        },
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 2),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: YakkuPalette.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
