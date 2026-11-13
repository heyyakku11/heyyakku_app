import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/domain/enums/poll_answer_type.dart';
import 'package:yakku/domain/enums/poll_status.dart';
import 'package:yakku/presentation/screens/inbox/active_cards_strip.dart';

PollModel _card({
  required PollStatus status,
  DateTime? expiresAt,
  DateTime? closedAt,
  required int votes,
  bool resultsUnlocked = true,
  bool isCheck = true,
}) {
  return PollModel(
    id: 'p${votes}_${status.name}',
    shareCode: 'code',
    question: 'Do people like me, or just like having me around?',
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: false,
    status: status,
    options: const [],
    totalVoteCount: votes,
    expiresAt: expiresAt,
    closedAt: closedAt,
    minVotes: 3,
    voteProgress: votes,
    resultsUnlocked: resultsUnlocked,
    isCheck: isCheck,
    checkTitle: 'Mirror Check',
    checkColor: '#FFE0E8',
  );
}

Future<void> _pump(WidgetTester tester, List<PollModel> cards) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ActiveCardsStrip(
          cards: cards,
          onOpen: (_) {},
          onShareAgain: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a live card whose result is available still shows Live and how long is left', (
    tester,
  ) async {
    await _pump(tester, [
      _card(
        status: PollStatus.active,
        expiresAt: DateTime.now().add(const Duration(hours: 18, minutes: 30)),
        votes: 7,
      ),
    ]);

    expect(find.text('Live · 18h left'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('friends voted'), findsOneWidget);
    expect(find.text('See live result'), findsOneWidget);
    expect(find.textContaining('Ended'), findsNothing);
  });

  testWidgets('the time left counts down in days, hours and minutes', (
    tester,
  ) async {
    await _pump(tester, [
      _card(
        status: PollStatus.active,
        expiresAt: DateTime.now().add(const Duration(days: 2, hours: 3)),
        votes: 5,
      ),
      _card(
        status: PollStatus.active,
        expiresAt: DateTime.now().add(const Duration(minutes: 20)),
        votes: 4,
      ),
    ]);

    expect(find.text('Live · 2d left'), findsOneWidget);
    expect(find.text('Live · 19m left'), findsOneWidget);
  });

  testWidgets('a card that ended with a result shows Ended and the final result', (
    tester,
  ) async {
    await _pump(tester, [
      _card(
        status: PollStatus.inactive,
        closedAt: DateTime.now().subtract(const Duration(hours: 2)),
        votes: 12,
      ),
    ]);

    expect(find.text('Ended · result ready'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('friends voted'), findsOneWidget);
    expect(find.text('See final result'), findsOneWidget);
    expect(find.textContaining('Live'), findsNothing);
  });

  testWidgets('a card past its end time is ended even if still marked active', (
    tester,
  ) async {
    await _pump(tester, [
      _card(
        status: PollStatus.active,
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        votes: 9,
      ),
    ]);

    expect(find.text('Ended · result ready'), findsOneWidget);
  });

  testWidgets('a live card under the vote limit shows progress and Share again', (
    tester,
  ) async {
    await _pump(tester, [
      _card(
        status: PollStatus.active,
        expiresAt: DateTime.now().add(const Duration(hours: 5, minutes: 30)),
        votes: 2,
        resultsUnlocked: false,
      ),
    ]);

    expect(find.text('Live · 5h left'), findsOneWidget);
    expect(find.text('2 of 3 votes · 1 more to see results'), findsOneWidget);
    expect(find.text('Share again'), findsOneWidget);
  });
}
