import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/widgets/confetti_burst.dart';
import 'package:yakku/presentation/widgets/personality_share_card.dart';

/// Owner locked-progress view: mirrors poll/check [ResultsLockedView] with the
/// personality theme (raspberry + WHO YOU ARE preview + vote counter).
///
/// Used from the share-link own path and from personality vote notifications.
class PersonalityOwnLockedView extends StatelessWidget {
  const PersonalityOwnLockedView({
    super.key,
    required this.status,
    required this.totalVotes,
    required this.requiredVotes,
    required this.traitNames,
    required this.busy,
    this.onMakeGuess,
    this.onShareAgain,
    this.onViewResults,
    /// Confetti only from the ready push (`personalityReady`), not share links.
    this.showConfetti = false,
  });

  final PersonalityCardStatus status;
  final int totalVotes;
  final int requiredVotes;
  final List<String> traitNames;
  final bool busy;
  final VoidCallback? onMakeGuess;
  final VoidCallback? onShareAgain;
  final VoidCallback? onViewResults;
  final bool showConfetti;

  static const _accent = YakkuPalette.Raspberry;

  @override
  Widget build(BuildContext context) {
    final resultsReady = status == PersonalityCardStatus.completed;
    final needed = requiredVotes.clamp(1, 99);
    final filled = totalVotes.clamp(0, needed);

    final body = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(child: _PersonalityOwnerTag()),
                const SizedBox(height: 18),
                Center(
                  child: PersonalityShareCard(
                    traits: traitNames,
                    width: 300,
                    tilt: -0.04,
                  ),
                ),
                const SizedBox(height: 28),
                if (resultsReady)
                  const _PersonalityReadyPanel()
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
                          Text(
                            status == PersonalityCardStatus.draft
                                ? 'Make your guess before friends answer'
                                : '$filled of $needed votes',
                            style: const TextStyle(
                              color: YakkuPalette.Ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (status != PersonalityCardStatus.draft) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                for (var i = 0; i < needed; i++) ...[
                                  if (i > 0) const SizedBox(width: 6),
                                  Expanded(
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: i < filled
                                            ? _accent
                                            : YakkuPalette.blushFill,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            status == PersonalityCardStatus.draft
                                ? 'Pick 3 traits first, then share. You cannot vote on your own card.'
                                : 'Results show at $needed votes. Friends stay anonymous — including you.',
                            style: const TextStyle(
                              color: YakkuPalette.textSecondary,
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          child: _PersonalityOwnActionButton(
            busy: busy,
            status: status,
            onMakeGuess: onMakeGuess,
            onShareAgain: onShareAgain,
            onViewResults: onViewResults,
          ),
        ),
      ],
    );

    if (!resultsReady || !showConfetti) return body;
    return Stack(
      children: [
        body,
        const Positioned.fill(
          child: ConfettiBurst(
            colors: [
              _accent,
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

class _PersonalityOwnerTag extends StatelessWidget {
  const _PersonalityOwnerTag();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.Raspberry.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: YakkuPalette.Raspberry.withValues(alpha: 0.35),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 16, color: YakkuPalette.Raspberry),
            SizedBox(width: 6),
            Text(
              'THIS IS YOUR CARD',
              style: TextStyle(
                color: YakkuPalette.Raspberry,
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

class _PersonalityReadyPanel extends StatelessWidget {
  const _PersonalityReadyPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: YakkuPalette.Raspberry.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: YakkuPalette.Raspberry.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Text('🎉', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your results are ready!',
                    style: TextStyle(
                      color: YakkuPalette.Ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'See how your friends describe you.',
                    style: TextStyle(
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

class _PersonalityOwnActionButton extends StatelessWidget {
  const _PersonalityOwnActionButton({
    required this.busy,
    required this.status,
    this.onMakeGuess,
    this.onShareAgain,
    this.onViewResults,
  });

  final bool busy;
  final PersonalityCardStatus status;
  final VoidCallback? onMakeGuess;
  final VoidCallback? onShareAgain;
  final VoidCallback? onViewResults;

  @override
  Widget build(BuildContext context) {
    final (label, icon, onPressed) = switch (status) {
      PersonalityCardStatus.draft => (
        'Make your guess',
        Icons.auto_awesome_rounded,
        onMakeGuess,
      ),
      PersonalityCardStatus.collecting => (
        'Share again',
        Icons.ios_share_rounded,
        onShareAgain,
      ),
      PersonalityCardStatus.completed => (
        'View results',
        Icons.bar_chart_rounded,
        onViewResults,
      ),
    };

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: YakkuPalette.Raspberry,
          disabledBackgroundColor: YakkuPalette.Raspberry.withValues(
            alpha: 0.45,
          ),
          foregroundColor: YakkuPalette.white,
          shape: const StadiumBorder(),
        ),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: YakkuPalette.white,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          busy ? 'Opening…' : label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
