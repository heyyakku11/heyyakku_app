import 'package:flutter/material.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/screens/share/card_share_screen.dart';
import 'package:yakku/presentation/widgets/check_share_card.dart';

/// The route of the share screen for a card that already exists. Used right after making a card, and to share
/// it again later.
Route<void> cardShareRoute({
  required String shareCode,
  required String title,
  required String question,
  required List<String> options,
  int minVotes = 0,
}) {
  return MaterialPageRoute<void>(
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
      story: CheckStoryCard(title: title, question: question, options: options),
    ),
  );
}

/// The share screen route for a poll the user made.
Route<void> pollShareRoute(PollResponse poll) {
  return cardShareRoute(
    shareCode: poll.shareCode,
    title: '',
    question: poll.question,
    options: [for (final option in poll.options) option.text ?? ''],
    minVotes: poll.minVotes,
  );
}

/// The share screen route for a check the user made.
Route<void> checkShareRoute(UserCheckResponse check) {
  return cardShareRoute(
    shareCode: check.shareCode,
    title: check.title,
    question: check.question.trim().isNotEmpty ? check.question : check.title,
    options: [for (final option in check.options) option.text],
    minVotes: check.minVotes,
  );
}

/// Opens the share screen for a card that already exists.
Future<void> openCardShare(
  BuildContext context, {
  required String shareCode,
  required String title,
  required String question,
  required List<String> options,
  int minVotes = 0,
}) {
  return Navigator.of(context).push<void>(
    cardShareRoute(
      shareCode: shareCode,
      title: title,
      question: question,
      options: options,
      minVotes: minVotes,
    ),
  );
}
