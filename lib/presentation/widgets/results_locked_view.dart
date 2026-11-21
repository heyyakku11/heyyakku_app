import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/check_theme.dart';
import 'package:yakku/presentation/widgets/confetti_burst.dart';
import 'package:yakku/core/utils/hex_color.dart';

/// Shown instead of results while a card is under its vote limit: the card with its answers hidden, how many
/// votes it has out of how many it needs, and when it closes. A live card can be shared again from the button
/// pinned to the bottom. A closed card shows when it closed and has no share button: it has to be reshared first.
/// Picks are never shown under the limit, so the options are blank bars.
class ResultsLockedView extends StatelessWidget {
  const ResultsLockedView({
    super.key,
    required this.question,
    required this.options,
    required this.progress,
    required this.minVotes,
    this.onShareAgain,
    this.tag,
    this.backgroundColor,
    this.cardColor,
    this.tagColor,
    this.questionColor,
    this.optionColor,
    this.accentColor,
    this.sticker,
    this.stickerColor,
    this.ownerLabel,
    this.resultsReady = false,
    /// Confetti only from the ready push (`cardResultsReady`), not share links.
    this.showConfetti = false,
    this.totalVotes = 0,
    this.onViewResults,
    this.closesAt,
    this.closedAt,
    this.closed = false,
  });

  final String question;

  /// Option labels of the card. Only how many there are is used: their text stays hidden.
  final List<String> options;

  /// Votes received so far, not counting the owner's own answer.
  final int progress;
  final int minVotes;

  /// Opens the share screen. Null when the card is closed: sharing waits until it is reshared.
  final VoidCallback? onShareAgain;

  /// Small caption at the top right of the card, e.g. "TRUST CHECK".
  final String? tag;

  /// Hex colour of the card, when it has one.
  final String? backgroundColor;

  /// The card colour as a [Color], for callers that already parsed a theme. Wins over [backgroundColor].
  final Color? cardColor;

  /// Colours from the card's own theme: the name of the check ([tag]), the question, the answer rows, the accent
  /// of the letter badges and the "+", and the sticker. Each falls back to a neutral default.
  final Color? tagColor;
  final Color? questionColor;
  final Color? optionColor;
  final Color? accentColor;

  /// The handwritten sticker at the top right. Defaults to the app's check sticker when the card has a name.
  final String? sticker;
  final Color? stickerColor;

  /// A tag above the card, e.g. "This is your card", for when the owner opens it from a link.
  final String? ownerLabel;

  /// True once the results can be opened. The vote-progress panel becomes a "results are ready" panel
  /// and the bottom button opens the results ([onViewResults]) instead of sharing again.
  final bool resultsReady;

  /// Party-popper overlay. Only set from the ready push path.
  final bool showConfetti;

  /// How many friends answered; shown in the ready panel.
  final int totalVotes;
  final VoidCallback? onViewResults;

  /// When the card closes; null when it has no end (the "Closes in" label is then left out).
  final DateTime? closesAt;

  /// When the owner closed the card by hand. A closed card shows "Closed 3h ago", never "Closes in".
  final DateTime? closedAt;

  /// True when the card is closed even if [closedAt] was not sent. Never shows the upcoming expiry then.
  final bool closed;

  static const _ink = YakkuPalette.textPrimary;
  static const _muted = YakkuPalette.textSecondary;
  static const _mint = YakkuPalette.mint;

  static String _span(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    return '${d.inMinutes.clamp(1, 59)}m';
  }

  /// The status line: "Closed 3h ago" for a card that was closed (by the owner, or because its time ran out),
  /// "Closes in 2h" while it is still open with an end time, and nothing for a card without an end.
  ({String text, bool closed})? _statusLabel() {
    final now = DateTime.now();
    if (closed || closedAt != null) {
      final when =
          closedAt ??
          (closesAt != null && !closesAt!.isAfter(now) ? closesAt : null);
      if (when == null) return (text: 'Closed', closed: true);
      final age = now.difference(when);
      if (age.isNegative || age.inMinutes < 1) {
        return (text: 'Closed just now', closed: true);
      }
      return (text: 'Closed ${_span(age)} ago', closed: true);
    }
    final end = closesAt;
    if (end == null) return null;
    final left = end.difference(now);
    if (left.isNegative) {
      return (text: 'Closed ${_span(left.abs())} ago', closed: true);
    }
    return (text: 'Closes in ${_span(left)}', closed: false);
  }

  @override
  Widget build(BuildContext context) {
    final cardColor =
        this.cardColor ?? parseHexColor(backgroundColor ?? '', fallback: _mint);
    final filled = progress.clamp(0, minVotes);
    final status = _statusLabel();

    final accent = accentColor ?? YakkuPalette.primary;

    final body = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ownerLabel != null && ownerLabel!.trim().isNotEmpty) ...[
                  Align(
                    child: _OwnerTag(
                      label: ownerLabel!.trim(),
                      color: accentColor ?? YakkuPalette.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                _LockedCard(
                  question: question,
                  options: options,
                  color: cardColor,
                  accent: accentColor ?? YakkuPalette.primary,
                  heading: tag,
                  // A card with a name is a check: it carries the app's fixed sticker unless the theme sets one.
                  sticker:
                      sticker ??
                      ((tag?.trim().isNotEmpty ?? false)
                          ? kCheckSticker
                          : null),
                  headingColor: tagColor,
                  stickerColor: stickerColor,
                  questionColor: questionColor,
                  optionColor: optionColor,
                ),
                const SizedBox(height: 28),
                if (resultsReady)
                  _ReadyPanel(votes: totalVotes, accent: accent)
                else
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
                              if (status != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      status.closed
                                          ? Icons.lock_clock_rounded
                                          : Icons.schedule_rounded,
                                      size: 14,
                                      color: status.closed
                                          ? _muted
                                          : YakkuPalette.Error,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status.text,
                                      style: TextStyle(
                                        color: status.closed
                                            ? _muted
                                            : YakkuPalette.Error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
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
                          const SizedBox(height: 14),
                          Text(
                            'Results show at $minVotes votes. That keeps every friend anonymous.',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12.5,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (resultsReady && onViewResults != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: onViewResults,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: YakkuPalette.white,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.bar_chart_rounded, size: 20),
                label: const Text(
                  'View results',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          )
        else if (onShareAgain != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: onShareAgain,
                style: FilledButton.styleFrom(
                  backgroundColor: YakkuPalette.primary,
                  foregroundColor: YakkuPalette.white,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text(
                  'Share again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          )
        else
          const SizedBox(height: 12),
      ],
    );

    if (!resultsReady || !showConfetti) return body;
    // Party popper over the whole view, from the bottom corners.
    return Stack(
      children: [
        body,
        Positioned.fill(
          child: ConfettiBurst(
            colors: [
              accent,
              YakkuPalette.Gold,
              YakkuPalette.Blush,
              YakkuPalette.skyBlue,
              YakkuPalette.mintBright,
              YakkuPalette.violetTint,
            ],
          ),
        ),
      ],
    );
  }
}

/// Replaces the vote progress when the results are ready: a bouncing party popper, the headline and how many
/// friends answered.
class _ReadyPanel extends StatelessWidget {
  const _ReadyPanel({required this.votes, required this.accent});

  final int votes;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final who = votes == 1 ? '1 friend answered' : '$votes friends answered';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(
                scale: value.clamp(0.0, 1.4),
                child: Transform.rotate(
                  angle: (1 - value) * -0.6,
                  child: child,
                ),
              ),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Text('🎉', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your results are ready!',
                    style: TextStyle(
                      color: YakkuPalette.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    votes > 0
                        ? '$who. See what your circle really thinks.'
                        : 'See what your circle really thinks.',
                    style: const TextStyle(
                      color: YakkuPalette.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
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

/// The card as friends see it: Yakku wordmark and sticker on top, the check's name, the question, the answers
/// blurred (their labels stay unreadable here) and a "Friends add their own" row. It keeps the colours of the
/// card's own theme; anything the theme does not give falls back to a neutral shade of the card's ink.
class _LockedCard extends StatelessWidget {
  const _LockedCard({
    required this.question,
    required this.options,
    required this.color,
    required this.accent,
    this.heading,
    this.sticker,
    this.headingColor,
    this.stickerColor,
    this.questionColor,
    this.optionColor,
  });

  final String question;
  final List<String> options;
  final Color color;
  final Color accent;
  final String? heading;
  final String? sticker;
  final Color? headingColor;
  final Color? stickerColor;
  final Color? questionColor;
  final Color? optionColor;

  static const _ink = YakkuPalette.textPrimary;
  static const _friendsAddOwn = 'Friends add their own';
  static const _cta = 'Answer anonymously';

  @override
  Widget build(BuildContext context) {
    final title = heading?.trim() ?? '';
    final stickerText = sticker?.trim() ?? '';
    final shown = options.take(4).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Transform.rotate(
        angle: -3 * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _ink, width: 2.5),
            boxShadow: const [BoxShadow(color: _ink, offset: Offset(-2, 7))],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: _CardWordmark(),
                    ),
                    const Spacer(),
                    if (stickerText.isNotEmpty)
                      Flexible(
                        child: _CardSticker(
                          text: stickerText,
                          color: stickerColor ?? accent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    style: TextStyle(
                      color: headingColor ?? _ink,
                      fontSize: 30,
                      height: 1.02,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  question,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: questionColor ?? _ink,
                    fontSize: 19,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < shown.length; i++) ...[
                  _BlurredOption(
                    letter: String.fromCharCode(65 + i),
                    text: shown[i],
                    color: optionColor ?? YakkuPalette.white,
                    accent: accent,
                  ),
                  const SizedBox(height: 8),
                ],
                _FriendsAddOwnRow(
                  letter: String.fromCharCode(65 + shown.length),
                  label: _friendsAddOwn,
                  accent: accent,
                ),
                const SizedBox(height: 14),
                const _AnswerCta(label: _cta),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill above the card that says whose card it is.
class _OwnerTag extends StatelessWidget {
  const _OwnerTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardWordmark extends StatelessWidget {
  const _CardWordmark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Yakku',
          style: TextStyle(
            color: YakkuPalette.textPrimary,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 2, bottom: 3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: YakkuPalette.Dot,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 5, height: 5),
          ),
        ),
      ],
    );
  }
}

/// The handwritten sticker in the card's top-right corner.
class _CardSticker extends StatelessWidget {
  const _CardSticker({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: YakkuPalette.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: YakkuPalette.textPrimary),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pacifico',
              color: color,
              fontSize: 15,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

/// An answer row whose text is blurred: the lettered badge stays, the words do not.
class _BlurredOption extends StatelessWidget {
  const _BlurredOption({
    required this.letter,
    required this.text,
    required this.color,
    required this.accent,
  });

  final String letter;
  final String text;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  color: YakkuPalette.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: YakkuPalette.textPrimary,
                    fontSize: 15,
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
}

/// The dashed "Friends add their own +" row.
class _FriendsAddOwnRow extends StatelessWidget {
  const _FriendsAddOwnRow({
    required this.letter,
    required this.label,
    required this.accent,
  });

  final String letter;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: accent.withAlpha(110),
        radius: 16,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: YakkuPalette.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: YakkuPalette.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: YakkuPalette.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: YakkuPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.add, size: 22, color: accent),
            ],
          ),
        ),
      ),
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

/// The dark "Answer anonymously" button of the card preview. It only shows what friends are asked to tap, so
/// it does nothing here.
class _AnswerCta extends StatelessWidget {
  const _AnswerCta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: YakkuPalette.charcoal,
        borderRadius: BorderRadius.circular(27),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.primary, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_rounded, size: 18, color: YakkuPalette.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: YakkuPalette.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
