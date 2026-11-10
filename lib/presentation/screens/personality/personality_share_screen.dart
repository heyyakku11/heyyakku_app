import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/presentation/screens/share/card_share_screen.dart';
import 'package:yakku/presentation/widgets/personality_share_card.dart';

/// Share step for the user's personality card: a preview of what friends see
/// and the destinations to send it to.
class PersonalityShareScreen extends StatelessWidget {
  const PersonalityShareScreen({
    super.key,
    required this.shareCode,
    required this.traits,
    this.minVotes = 0,
  });

  /// Answers needed before the result shows; 0 uses the app default.
  final int minVotes;

  final String shareCode;

  /// Trait names for the (blurred) preview chips.
  final List<String> traits;

  @override
  Widget build(BuildContext context) {
    return CardShareScreen(
      minVotes: minVotes > 0 ? minVotes : AppLimits.minVotesToReveal,
      buildPayload: () => SharePayload.personality(shareCode: shareCode),
      preview: PersonalityShareCard(traits: traits, width: 310),
      story: PersonalityStoryCard(traits: traits),
    );
  }
}
