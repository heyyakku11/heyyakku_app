import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/personality/personality_card.dart';

/// "Describe me in 3 words": the user's own personality card at the top of the
/// Friends feed. Draft/collecting keep the promo layout; completed shows the
/// friends-say stickers card from the product design.
class PersonalityCardTile extends StatelessWidget {
  const PersonalityCardTile({
    super.key,
    required this.card,
    required this.traits,
    required this.onPressed,
    this.topTraits = const [],
  });

  /// How many trait chips are shown before the "+N more" chip.
  static const _visibleChips = 3;

  final PersonalityCard card;

  /// The full predefined trait list; empty while it has not loaded.
  final List<PersonalityTrait> traits;

  /// Crowd-top trait names once the card is completed (up to 3).
  final List<String> topTraits;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (card.isCompleted) {
      return _CompletedFriendsCard(topTraits: topTraits, onPressed: onPressed);
    }

    final collecting = card.status == PersonalityCardStatus.collecting;
    final needed = card.requiredVotes;
    final progress = '${card.totalVotes} of $needed friends';
    final remaining = (needed - card.totalVotes).clamp(0, needed);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.Raspberry,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _Tag(label: 'WHO YOU ARE'),
                const Spacer(),
                Text(
                  progress,
                  style: const TextStyle(
                    color: YakkuPalette.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              collecting
                  ? '$remaining more ${remaining == 1 ? 'friend' : 'friends'} '
                        'and this is who you are'
                  : 'Describe me in 3 words',
              style: const TextStyle(
                color: YakkuPalette.white,
                fontSize: 24,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.4,
              ),
            ),
            if (collecting) ...[
              const SizedBox(height: 16),
              _ProgressBar(filled: card.totalVotes, total: needed),
            ] else ...[
              const SizedBox(height: 7),
              Text(
                'Friends pick 3 of these ${traits.isEmpty ? '' : '${traits.length} '}'
                'traits. Once $needed friends answer, this is who you are.',
                style: TextStyle(
                  color: YakkuPalette.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              if (traits.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildChips(),
              ],
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: YakkuPalette.white,
                  foregroundColor: YakkuPalette.Ink,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Ask now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChips() {
    final shown = traits.take(_visibleChips).toList();
    final more = traits.length - shown.length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final trait in shown) _OutlineChip(label: trait.name),
        if (more > 0) _MoreChip(label: '+$more more'),
      ],
    );
  }
}

/// Completed personality: raspberry sticker card with tilted trait chips.
class _CompletedFriendsCard extends StatelessWidget {
  const _CompletedFriendsCard({
    required this.topTraits,
    required this.onPressed,
  });

  static const _stickers = [
    (color: YakkuPalette.Gold, angle: -0.08),
    (color: Color(0xFFFBD6DF), angle: 0.05),
    (color: Color(0xFFCFEBD9), angle: -0.04),
  ];

  final List<String> topTraits;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final traits = topTraits.take(3).toList();

    return Material(
      color: YakkuPalette.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: YakkuPalette.Raspberry,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: YakkuPalette.Ink, width: 2.2),
            boxShadow: const [
              BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'YOUR FRIENDS SAY YOU’RE',
                        style: TextStyle(
                          color: YakkuPalette.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: YakkuPalette.white,
                      size: 26,
                    ),
                  ],
                ),
                if (traits.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < traits.length; i++)
                        Transform.rotate(
                          angle: _stickers[i % _stickers.length].angle,
                          child: _TraitSticker(
                            label: traits[i],
                            color: _stickers[i % _stickers.length].color,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TraitSticker extends StatelessWidget {
  const _TraitSticker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YakkuPalette.Ink, width: 2),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        label.toLowerCase(),
        style: const TextStyle(
          color: YakkuPalette.Ink,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// One segment per vote needed; the first [filled] are solid white.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: i < filled
                    ? YakkuPalette.white
                    : YakkuPalette.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: YakkuPalette.Raspberry,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: YakkuPalette.white.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: YakkuPalette.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: YakkuPalette.Raspberry,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
