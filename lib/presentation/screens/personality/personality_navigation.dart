import 'package:flutter/material.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/screens/personality/personality_claim_screen.dart';
import 'package:yakku/presentation/screens/personality/personality_result_screen.dart';
import 'package:yakku/presentation/screens/personality/personality_share_screen.dart';

/// "Ask now" on the personality card, by where the card is:
/// - draft: the user has not made their own guess yet, so the claim screen
///   (step 1: pick 3 traits, then share);
/// - collecting: the guess is already in, so go straight to the share screen;
/// - completed: the result screen.
///
/// Returns true when the card changed (the guess was submitted) and should be
/// reloaded.
Future<bool> openPersonalityAsk(
  BuildContext context,
  PersonalityCard card,
  List<PersonalityTrait> traits,
) async {
  switch (card.status) {
    case PersonalityCardStatus.draft:
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PersonalityClaimScreen(card: card, traits: traits),
          fullscreenDialog: true,
        ),
      );
      return changed == true;
    case PersonalityCardStatus.collecting:
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PersonalityShareScreen(
            shareCode: card.shareCode,
            minVotes: card.requiredVotes,
            traits: [for (final trait in traits) trait.name],
          ),
        ),
      );
      return false;
    case PersonalityCardStatus.completed:
      await openPersonalityResult(context, card);
      return false;
  }
}

/// The completed card's result: who friends say you are, against your guess.
Future<void> openPersonalityResult(BuildContext context, PersonalityCard card) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => PersonalityResultScreen(shareCode: card.shareCode),
    ),
  );
}
