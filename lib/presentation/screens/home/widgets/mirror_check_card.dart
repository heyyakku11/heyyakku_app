import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/presentation/screens/home/widgets/feed_shared.dart';

/// Featured / ongoing Mirror Check — always used for [mirrorChecks] index 0.
class CurrentMirrorCheckCard extends StatelessWidget {
  const CurrentMirrorCheckCard({super.key, required this.check});

  final MirrorCheck check;

  static const _defaultEyebrow = "THIS WEEK'S DROP";
  static const _defaultMeta = 'Ends Sunday';
  static const _friendsAddOneLabel = 'Friends add one';
  static const _hiddenPct = '??%';

  @override
  Widget build(BuildContext context) {
    final muted = check.foregroundColor.withValues(alpha: 0.55);
    final draft = AskFriendsCheck.fromMirrorCheck(check);
    final eyebrow = (check.eyebrow?.trim().isNotEmpty ?? false)
        ? check.eyebrow!.trim()
        : _defaultEyebrow;
    final meta = (check.meta?.trim().isNotEmpty ?? false)
        ? check.meta!.trim()
        : _defaultMeta;
    final displayOptions = _displayOptions(check.options);

    return GestureDetector(
      onTap: () => openAskFriendsCheck(context, draft),
      child: DecoratedBox(
        decoration: feedCardDecoration(check.backgroundColor, radius: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: YakkuPalette.black,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: check.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  eyebrow,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: YakkuPalette.white.withValues(alpha: 0.72),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (check.sticker != null)
                    Expanded(
                      child: _CurrentCheckSticker(
                        text: check.sticker!,
                        color: check.accentColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                check.title,
                style: TextStyle(
                  color: check.foregroundColor,
                  fontSize: 34,
                  height: 1.02,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              if (check.question.isNotEmpty &&
                  check.question != check.title) ...[
                const SizedBox(height: 8),
                Text(
                  check.question,
                  style: TextStyle(
                    color: check.foregroundColor,
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (var i = 0; i < displayOptions.length; i++) ...[
                _LetteredOption(
                  option: displayOptions[i],
                  check: check,
                  letter:
                      displayOptions[i].letter ?? String.fromCharCode(65 + i),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              _AskMyFriendsButton(
                onTap: () => openAskFriendsCheck(context, draft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MirrorCheckOption> _displayOptions(List<MirrorCheckOption> options) {
    final hasOutlined = options.any((option) => option.outlined);
    final withTrailing = [
      for (final option in options)
        MirrorCheckOption(
          label: option.label,
          letter: option.letter,
          trailing: option.outlined ? null : _hiddenPct,
          outlined: option.outlined,
        ),
    ];

    if (hasOutlined) return withTrailing;

    return [
      ...withTrailing,
      MirrorCheckOption(
        label: _friendsAddOneLabel,
        letter: String.fromCharCode(65 + withTrailing.length),
        outlined: true,
      ),
    ];
  }
}

/// Local to [CurrentMirrorCheckCard] — customize independently of other cards.
class _CurrentCheckSticker extends StatelessWidget {
  const _CurrentCheckSticker({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: YakkuPalette.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: YakkuPalette.black),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pacifico',
              color: color,
              fontSize: 22,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

/// Local to [CurrentMirrorCheckCard] — customize independently of other cards.
class _AskMyFriendsButton extends StatelessWidget {
  const _AskMyFriendsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YakkuPalette.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: YakkuPalette.charcoal,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ios_share, size: 20, color: YakkuPalette.white),
                SizedBox(width: 6),
                Text(
                  'Ask my friends',
                  style: TextStyle(
                    color: YakkuPalette.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

class _LetteredOption extends StatelessWidget {
  const _LetteredOption({
    required this.option,
    required this.check,
    required this.letter,
  });

  final MirrorCheckOption option;
  final MirrorCheck check;
  final String letter;

  @override
  Widget build(BuildContext context) {
    final outlined = option.outlined;
    final badgeColor = check.accentColor.withValues(alpha: 0.14);
    final dashColor = check.foregroundColor.withValues(alpha: 0.35);

    final row = Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: outlined ? YakkuPalette.transparent : badgeColor,
              shape: BoxShape.circle,
              border: outlined ? Border.all(color: dashColor) : null,
            ),
            child: Text(
              letter,
              style: TextStyle(
                color: outlined
                    ? check.foregroundColor.withValues(alpha: 0.7)
                    : check.foregroundColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              option.label,
              style: TextStyle(
                color: check.foregroundColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (option.trailing != null)
            Text(
              option.trailing!,
              style: TextStyle(
                color: check.foregroundColor.withValues(alpha: 0.35),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
        ],
      ),
    );

    if (outlined) {
      return CustomPaint(
        painter: _DashedBorderPainter(color: dashColor, radius: 14),
        child: row,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: check.chipColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: row,
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
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
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
