import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/screens/share/card_share_screen.dart';

/// "Share your result": the poster of an ended card (the check, the question
/// and You vs Your circle, no names, counts or reasons) with the usual share
/// destinations underneath.
class ShareResultScreen extends StatelessWidget {
  const ShareResultScreen({
    super.key,
    required this.shareCode,
    required this.question,
    required this.myLabel,
    required this.crowdLabel,
    required this.crowdPercent,
    this.verdict,
    this.pickLabel,
    this.tag = 'Mirror Check',
    this.options = const [],
    this.minVotes = 3,
  });

  /// The card's share code: the link that gets shared.
  final String shareCode;
  final String question;

  /// The viewer's own answer.
  final String myLabel;

  /// The circle's top answer and the share of voters who picked it.
  final String crowdLabel;
  final int crowdPercent;

  /// "Plot twist." or "Bang on."; null when there is no pick to compare.
  final String? verdict;

  /// The sharer's own pick when it is one of the listed answers; the web result page shows it as "You".
  final String? pickLabel;

  /// The check's type name, shown above the question.
  final String tag;
  final List<String> options;
  final int minVotes;

  @override
  Widget build(BuildContext context) {
    Widget poster() => ResultPoster(
      tag: tag,
      question: question,
      myLabel: myLabel,
      crowdLabel: crowdLabel,
      crowdPercent: crowdPercent,
      verdict: verdict,
    );

    return CardShareScreen(
      title: 'Share your result',
      minVotes: minVotes,
      buildPayload: () => SharePayload.create(
        shareCode: shareCode,
        question: question,
        options: options,
        // The link opens the result on the website, not the voting form.
        path: 'result',
        query: pickLabel == null ? null : {'you': pickLabel!},
      ),
      preview: poster(),
      // The same poster on a 360x640 canvas for Instagram Stories.
      story: SizedBox(
        width: 360,
        height: 640,
        child: ColoredBox(
          color: YakkuPalette.cream,
          child: Center(child: Transform.scale(scale: 1.1, child: poster())),
        ),
      ),
    );
  }
}

/// The tilted pink result card.
class ResultPoster extends StatelessWidget {
  const ResultPoster({
    super.key,
    required this.tag,
    required this.question,
    required this.myLabel,
    required this.crowdLabel,
    required this.crowdPercent,
    this.verdict,
  });

  final String tag;
  final String question;
  final String myLabel;
  final String crowdLabel;
  final int crowdPercent;
  final String? verdict;

  static const _night = Color(0xFF1F191C);

  @override
  Widget build(BuildContext context) {
    final bangOn = verdict == 'Bang on.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Transform.rotate(
        angle: -4 * math.pi / 180,
        child: Container(
          width: 310,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: YakkuPalette.pinkTint,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _night, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text.rich(
                TextSpan(
                  text: 'Yakku',
                  children: [
                    TextSpan(
                      text: '.',
                      style: TextStyle(color: YakkuPalette.Raspberry),
                    ),
                  ],
                ),
                style: TextStyle(
                  color: _night,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tag.toUpperCase(),
                style: const TextStyle(
                  color: YakkuPalette.Raspberry,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                question,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _night,
                  fontSize: 23,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 38),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: verdict == null ? 0 : 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _night,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 140,
                          child: Row(
                            children: [
                              Expanded(
                                child: _Panel(
                                  color: YakkuPalette.cardPink,
                                  tag: 'You',
                                  label: myLabel,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _Panel(
                                  color: YakkuPalette.white,
                                  tag: 'Your circle',
                                  percent: '$crowdPercent%',
                                  label: crowdLabel,
                                  light: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _night,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: YakkuPalette.white,
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            'vs',
                            style: TextStyle(
                              color: YakkuPalette.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (verdict != null)
                    Positioned(
                      top: -10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Transform.rotate(
                          angle: 0.06,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: bangOn
                                  ? const Color(0xFFD7F5E3)
                                  : YakkuPalette.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: bangOn
                                    ? const Color(0xFF1E6B3E)
                                    : _night,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              verdict!,
                              style: TextStyle(
                                color: bangOn
                                    ? const Color(0xFF1E6B3E)
                                    : YakkuPalette.Raspberry,
                                fontSize: 20,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.color,
    required this.tag,
    required this.label,
    this.percent,
    this.light = false,
  });

  final Color color;
  final String tag;
  final String label;
  final String? percent;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    tag,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: light
                          ? YakkuPalette.textSecondary
                          : ResultPoster._night,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (percent != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    percent!,
                    style: const TextStyle(
                      color: YakkuPalette.Raspberry,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ResultPoster._night,
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
