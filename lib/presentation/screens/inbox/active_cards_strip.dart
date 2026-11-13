import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/utils/hex_color.dart';
import 'package:yakku/data/models/Poll.dart';

/// "Active cards · 3": the user's live cards and the ones that just ended with
/// a result, side by side. Each card is in one of three states:
/// - live, fewer votes than needed: progress towards the result, "Share again";
/// - live, enough votes: the number of friends so far, "See live result";
/// - ended with a result: the final number, "See final result".
class ActiveCardsStrip extends StatelessWidget {
  const ActiveCardsStrip({
    super.key,
    required this.cards,
    required this.onOpen,
    required this.onShareAgain,
  });

  final List<PollModel> cards;
  final void Function(PollModel card) onOpen;
  final void Function(PollModel card) onShareAgain;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final width = (MediaQuery.of(context).size.width * 0.72).clamp(
      240.0,
      320.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active cards · ${cards.length}',
          style: const TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final card in cards) ...[
                  SizedBox(
                    width: width,
                    child: _ActiveCard(
                      poll: card,
                      onOpen: () => onOpen(card),
                      onShareAgain: () => onShareAgain(card),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

enum _State { liveUnder, liveResult, ended }

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.poll,
    required this.onOpen,
    required this.onShareAgain,
  });

  static const _pollColor = Color(0xFFEAF6C6);

  final PollModel poll;
  final VoidCallback onOpen;
  final VoidCallback onShareAgain;

  bool get _live {
    if (!poll.status.isActive) return false;
    final expiresAt = poll.expiresAt;
    return expiresAt == null || expiresAt.isAfter(DateTime.now());
  }

  _State get _state => !_live
      ? _State.ended
      : (poll.resultsUnlocked ? _State.liveResult : _State.liveUnder);

  String get _timeLeft {
    final expiresAt = poll.expiresAt;
    if (expiresAt == null) return 'Live';
    final d = expiresAt.difference(DateTime.now());
    if (d.inDays >= 1) return 'Live · ${d.inDays}d left';
    if (d.inHours >= 1) return 'Live · ${d.inHours}h left';
    return 'Live · ${d.inMinutes.clamp(1, 59)}m left';
  }

  @override
  Widget build(BuildContext context) {
    final color = poll.isCheck
        ? parseHexColor(poll.checkColor, fallback: _pollColor)
        : _pollColor;
    // A darker shade of the card's own colour for the small labels and bars.
    final accent = HSLColor.fromColor(
      color,
    ).withLightness(0.27).withSaturation(0.55).toColor();
    final label = poll.isCheck
        ? (poll.checkTitle ?? 'CHECK').toUpperCase()
        : 'YOUR QUESTION';
    final state = _state;

    final footer = switch (state) {
      _State.liveUnder => 'Share again',
      _State.liveResult => 'See live result',
      _State.ended => 'See final result',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: state == _State.liveUnder ? onShareAgain : onOpen,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: YakkuPalette.Ink, width: 1.5),
            boxShadow: const [
              BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                poll.question,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 21,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const Spacer(),
              const SizedBox(height: 12),
              if (state == _State.liveUnder)
                _Progress(poll: poll, accent: accent)
              else
                _VotedCount(
                  count: poll.totalVoteCount,
                  accent: accent,
                  final_: state == _State.ended,
                ),
              const SizedBox(height: 10),
              _StatusChip(
                text: state == _State.ended
                    ? 'Ended · result ready'
                    : _timeLeft,
                live: state != _State.ended,
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: YakkuPalette.Ink.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      footer,
                      style: const TextStyle(
                        color: YakkuPalette.Ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: YakkuPalette.Ink,
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

class _Progress extends StatelessWidget {
  const _Progress({required this.poll, required this.accent});

  final PollModel poll;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final needed = poll.minVotes > 0 ? poll.minVotes : 3;
    final done = poll.voteProgress.clamp(0, needed);
    final more = needed - done;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < needed; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: i < done ? accent : accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '$done of $needed votes · $more more to see results',
          style: TextStyle(
            color: accent,
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VotedCount extends StatelessWidget {
  const _VotedCount({
    required this.count,
    required this.accent,
    required this.final_,
  });

  final int count;
  final Color accent;
  final bool final_;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 32,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'friends voted',
          style: TextStyle(
            color: accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.live});

  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: YakkuPalette.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2E9E5B),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
