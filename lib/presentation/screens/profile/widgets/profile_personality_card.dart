import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/personality/personality_card.dart';

/// The personality card on the profile. It looks different at each stage:
/// - draft: the user has not made their own guess yet;
/// - collecting: friends are answering, with a progress bar;
/// - completed: the top three traits friends picked.
class ProfilePersonalityCard extends StatelessWidget {
  const ProfilePersonalityCard({
    super.key,
    required this.card,
    required this.traitCount,
    required this.topTraits,
    required this.showInCommunity,
    required this.onAskNow,
    required this.onFullResult,
    required this.onShowInCommunityChanged,
  });

  final PersonalityCard card;

  /// How many predefined traits exist (0 until loaded).
  final int traitCount;

  /// Names of what friends picked most, for the completed card.
  final List<String> topTraits;
  final bool showInCommunity;
  final VoidCallback onAskNow;
  final VoidCallback onFullResult;
  final ValueChanged<bool> onShowInCommunityChanged;

  @override
  Widget build(BuildContext context) {
    return switch (card.status) {
      PersonalityCardStatus.completed => _CompletedCard(
        card: card,
        topTraits: topTraits,
        showInCommunity: showInCommunity,
        onFullResult: onFullResult,
        onShowInCommunityChanged: onShowInCommunityChanged,
      ),
      PersonalityCardStatus.collecting => _PendingCard(
        card: card,
        traitCount: traitCount,
        collecting: true,
        onAskNow: onAskNow,
      ),
      PersonalityCardStatus.draft => _PendingCard(
        card: card,
        traitCount: traitCount,
        collecting: false,
        onAskNow: onAskNow,
      ),
    };
  }
}

/// Draft and collecting: a white card with the progress and an "Ask now".
class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.card,
    required this.traitCount,
    required this.collecting,
    required this.onAskNow,
  });

  final PersonalityCard card;
  final int traitCount;
  final bool collecting;
  final VoidCallback onAskNow;

  @override
  Widget build(BuildContext context) {
    final needed = card.requiredVotes;
    final remaining = (needed - card.totalVotes).clamp(0, needed);

    final title = collecting
        ? '$remaining more ${remaining == 1 ? 'friend' : 'friends'} '
              'and this is who you are'
        : 'Describe me in 3 words';
    final body = collecting
        ? 'Your top 3 show here once $needed friends answer. Until then, '
              'nobody sees anything, not even you.'
        : 'Friends pick 3 of these ${traitCount > 0 ? '$traitCount ' : ''}'
              'traits. Once $needed friends answer, this is who you are.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YakkuPalette.roseBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'WHO YOU ARE',
                style: TextStyle(
                  color: YakkuPalette.Raspberry,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                '${card.totalVotes} of $needed friends',
                style: const TextStyle(
                  color: YakkuPalette.Raspberry,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (collecting && needed > 0) ...[
            const SizedBox(height: 12),
            _Progress(filled: card.totalVotes, total: needed),
          ],
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onAskNow,
              style: OutlinedButton.styleFrom(
                foregroundColor: YakkuPalette.Ink,
                side: const BorderSide(color: YakkuPalette.Ink, width: 1.2),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Ask now',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: i < filled
                    ? YakkuPalette.Raspberry
                    : YakkuPalette.pinkWash.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Completed: a raspberry card with the traits friends picked as stickers.
class _CompletedCard extends StatelessWidget {
  const _CompletedCard({
    required this.card,
    required this.topTraits,
    required this.showInCommunity,
    required this.onFullResult,
    required this.onShowInCommunityChanged,
  });

  final PersonalityCard card;
  final List<String> topTraits;
  final bool showInCommunity;
  final VoidCallback onFullResult;
  final ValueChanged<bool> onShowInCommunityChanged;

  static const _sticker = [
    (color: YakkuPalette.Gold, angle: -0.05),
    (color: Color(0xFFFBD6DF), angle: 0.04),
    (color: Color(0xFFCFEBD9), angle: -0.03),
  ];

  @override
  Widget build(BuildContext context) {
    final traits = topTraits.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: YakkuPalette.Raspberry,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YakkuPalette.Ink, width: 1.5),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: YakkuPalette.Ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    'WHO YOU ARE',
                    style: TextStyle(
                      color: YakkuPalette.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'by ${card.totalVotes} friends',
                style: TextStyle(
                  color: YakkuPalette.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onFullResult,
                behavior: HitTestBehavior.opaque,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Full result',
                      style: TextStyle(
                        color: YakkuPalette.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: YakkuPalette.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your friends say you’re...',
            style: TextStyle(
              color: YakkuPalette.white,
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 14),
          if (traits.isNotEmpty)
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < traits.length; i++)
                    Transform.rotate(
                      angle: _sticker[i].angle,
                      child: _TraitSticker(
                        label: traits[i],
                        color: _sticker[i].color,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Show in Community',
                style: TextStyle(
                  color: YakkuPalette.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Switch(
                value: showInCommunity,
                onChanged: onShowInCommunityChanged,
                activeTrackColor: YakkuPalette.Gold,
                activeThumbColor: YakkuPalette.Ink,
                inactiveTrackColor: YakkuPalette.white.withValues(alpha: 0.25),
                inactiveThumbColor: YakkuPalette.white,
                trackOutlineColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YakkuPalette.Ink, width: 1.5),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: YakkuPalette.Ink,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
