import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/utils/hex_color.dart';

/// Shown instead of results while a card is under its vote limit: the card with its answers hidden, how many
/// votes it has out of how many it needs, when it closes, and a Share again button pinned to the bottom.
/// Picks are never shown under the limit, so the options are blank bars.
class ResultsLockedView extends StatelessWidget {
  const ResultsLockedView({
    super.key,
    required this.question,
    required this.options,
    required this.progress,
    required this.minVotes,
    required this.onShareAgain,
    this.tag,
    this.backgroundColor,
    this.closesAt,
    this.closedAt,
  });

  final String question;

  /// Option labels of the card. Only how many there are is used: their text stays hidden.
  final List<String> options;

  /// Votes received so far, not counting the owner's own answer.
  final int progress;
  final int minVotes;
  final VoidCallback onShareAgain;

  /// Small caption at the top right of the card, e.g. "TRUST CHECK".
  final String? tag;

  /// Hex colour of the card, when it has one.
  final String? backgroundColor;

  /// When the card closes; null when it has no end (the "Closes in" label is then left out).
  final DateTime? closesAt;

  /// When the owner closed the card by hand. A closed card shows "Closed 3h ago", never "Closes in".
  final DateTime? closedAt;

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
    final closed = closedAt;
    if (closed != null) {
      return (
        text: 'Closed ${_span(now.difference(closed))} ago',
        closed: true,
      );
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
    final cardColor = parseHexColor(backgroundColor ?? '', fallback: _mint);
    final filled = progress.clamp(0, minVotes);
    final status = _statusLabel();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LockedCard(
                  question: question,
                  optionCount: options.length.clamp(2, 4),
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
        ),
      ],
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard({
    required this.question,
    required this.optionCount,
    required this.color,
    this.tag,
  });

  final String question;
  final int optionCount;
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
                Row(
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
                    const Spacer(),
                    if (tag != null && tag!.trim().isNotEmpty)
                      Flexible(
                        child: Text(
                          tag!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: YakkuPalette.successGreen,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
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
                // The answers stay hidden below the vote limit: blank bars where they will be.
                for (var i = 0; i < optionCount; i++) ...[
                  Container(
                    height: 26,
                    decoration: BoxDecoration(
                      color: _ink.withAlpha(24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  if (i < optionCount - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
