import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/personality/personality_card.dart';

/// "Describe me in 3 words": the user's own personality card at the top of the
/// Friends feed. Friends pick 3 traits from the predefined list; once enough
/// have answered, the card shows who the user is.
class PersonalityCardTile extends StatelessWidget {
  const PersonalityCardTile({
    super.key,
    required this.card,
    required this.traits,
    required this.onPressed,
  });

  /// How many trait chips are shown before the "+N more" chip.
  static const _visibleChips = 3;

  final PersonalityCard card;

  /// The full predefined trait list; empty while it has not loaded.
  final List<PersonalityTrait> traits;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final done = card.isCompleted;
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
              done
                  ? 'Here is who you are'
                  : collecting
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
                done
                    ? '$needed friends have answered. See what they said.'
                    : 'Friends pick 3 of these ${traits.isEmpty ? '' : '${traits.length} '}'
                          'traits. Once $needed friends answer, this is who you are.',
                style: TextStyle(
                  color: YakkuPalette.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              if (!done && traits.isNotEmpty) ...[
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
                child: Text(
                  done ? 'See results' : 'Ask now',
                  style: const TextStyle(
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
