import 'package:flutter/material.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/presentation/screens/share/card_share_screen.dart';
import 'package:yakku/presentation/widgets/check_share_card.dart';

/// Opens the share screen for a card that already exists (the same one shown
/// right after making it).
Future<void> openCardShare(
  BuildContext context, {
  required String shareCode,
  required String title,
  required String question,
  required List<String> options,
  int minVotes = 0,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => CardShareScreen(
        minVotes: minVotes > 0 ? minVotes : 3,
        buildPayload: () => SharePayload.create(
          shareCode: shareCode,
          question: question,
          options: options,
        ),
        preview: CheckShareCard(
          title: title,
          question: question,
          options: options,
          width: 310,
        ),
        story: CheckStoryCard(
          title: title,
          question: question,
          options: options,
        ),
      ),
    ),
  );
}
