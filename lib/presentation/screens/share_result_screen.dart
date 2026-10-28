import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// Poster-style "You vs Crowd" page opened from the results card's
/// "Share this" button.
class ShareResultScreen extends StatelessWidget {
  const ShareResultScreen({
    super.key,
    required this.question,
    required this.myLabel,
    required this.crowdLabel,
    required this.crowdPercent,
    required this.voters,
    required this.headline,
    this.tag = 'Mirror Check',
  });

  final String question;

  /// The viewer's own answer.
  final String myLabel;

  /// The crowd's top answer and the share of voters who picked it.
  final String crowdLabel;
  final int crowdPercent;
  final int voters;

  /// Big closing line of the poster, e.g. "Plot twist.".
  final String headline;

  /// First chip next to the "You vs Crowd" chip.
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      appBar: AppBar(
        backgroundColor: YakkuPalette.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: YakkuPalette.textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: _Poster(
            tag: tag,
            question: question,
            myLabel: myLabel,
            crowdLabel: crowdLabel,
            crowdPercent: crowdPercent,
            voters: voters,
            headline: headline,
          ),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.tag,
    required this.question,
    required this.myLabel,
    required this.crowdLabel,
    required this.crowdPercent,
    required this.voters,
    required this.headline,
  });

  final String tag;
  final String question;
  final String myLabel;
  final String crowdLabel;
  final int crowdPercent;
  final int voters;
  final String headline;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: YakkuPalette.cream,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _Wordmark(),
                const Spacer(),
                _Chip(label: tag, filled: false),
                const SizedBox(width: 8),
                const _Chip(label: 'You vs Crowd', filled: true),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              question,
              style: const TextStyle(
                color: YakkuPalette.charcoal,
                fontSize: 26,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 26),
            Transform.rotate(
              angle: -3 * math.pi / 180,
              child: _VersusBoard(
                myLabel: myLabel,
                crowdLabel: crowdLabel,
                crowdPercent: crowdPercent,
                voters: voters,
              ),
            ),
            const SizedBox(height: 34),
            Text(
              headline,
              style: const TextStyle(
                color: YakkuPalette.primary,
                fontSize: 54,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: 'Yakku',
        children: [
          TextSpan(
            text: '.',
            style: TextStyle(color: YakkuPalette.primary),
          ),
        ],
      ),
      style: TextStyle(
        color: YakkuPalette.charcoal,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? YakkuPalette.charcoal : YakkuPalette.pinkTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? YakkuPalette.white : YakkuPalette.charcoal,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _VersusBoard extends StatelessWidget {
  const _VersusBoard({
    required this.myLabel,
    required this.crowdLabel,
    required this.crowdPercent,
    required this.voters,
  });

  final String myLabel;
  final String crowdLabel;
  final int crowdPercent;
  final int voters;

  static const _avatarColors = [
    YakkuPalette.butter,
    YakkuPalette.violetTint,
    YakkuPalette.accentGreen,
    YakkuPalette.skyTint,
  ];

  @override
  Widget build(BuildContext context) {
    final more = voters > _avatarColors.length ? voters - 4 : 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.charcoal,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: YakkuPalette.black25,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 230,
                  child: Row(
                    children: [
                      Expanded(
                        child: _Panel(
                          color: YakkuPalette.cardPink,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const _Avatar(),
                                  const SizedBox(width: 10),
                                  Text(
                                    'You',
                                    style: _title(YakkuPalette.charcoal, 24),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                myLabel,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: _title(YakkuPalette.charcoal, 22),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Panel(
                          color: YakkuPalette.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Crowd',
                                    style: _title(YakkuPalette.charcoal, 20),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '$crowdPercent%',
                                      style: _title(YakkuPalette.primary, 26),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                crowdLabel,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: _title(YakkuPalette.charcoal, 20),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  for (var i = 0; i < _avatarColors.length; i++)
                                    Align(
                                      widthFactor: 0.6,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: _avatarColors[i],
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: YakkuPalette.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const SizedBox(
                                          width: 26,
                                          height: 26,
                                        ),
                                      ),
                                    ),
                                  if (more > 0) ...[
                                    const SizedBox(width: 12),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: YakkuPalette.charcoal,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          '+$more',
                                          style: const TextStyle(
                                            color: YakkuPalette.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: YakkuPalette.charcoal,
                    shape: BoxShape.circle,
                    border: Border.all(color: YakkuPalette.white, width: 3),
                  ),
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Center(
                      child: Text(
                        'vs',
                        style: TextStyle(
                          color: YakkuPalette.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  voters == 1
                      ? '1 friend voted anonymously'
                      : '$voters friends voted anonymously',
                  style: const TextStyle(
                    color: YakkuPalette.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _title(Color color, double size) => TextStyle(
    color: color,
    fontSize: size,
    height: 1.1,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.pinkTint,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: YakkuPalette.charcoal, width: 2),
        ),
      ),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Text(
            'Y',
            style: TextStyle(
              color: YakkuPalette.charcoal,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
