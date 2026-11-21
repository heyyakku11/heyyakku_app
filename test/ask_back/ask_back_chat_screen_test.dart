import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_chat_screen.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/widgets/ask_back_unlock_sheet.dart';

import '../helpers/app_scope_fakes.dart';
import 'ask_back_controllers_test.dart'
    show FakeRealtime, FakeRemote, conversation, conversationId, message;

Future<FakeRemote> _open(
  WidgetTester tester, {
  AskBackConversation? current,
  List<AskBackMessage> history = const [],
  AskBackAccess? cardAccess,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final remote = FakeRemote([...history]);
  if (current != null) remote.current = current;
  if (cardAccess != null) remote.access = cardAccess;
  final realtime = FakeRealtime();
  final inbox = AskBackInboxController(remote: remote, realtime: realtime);

  await tester.pumpWidget(
    testAppScope(
      askBack: remote,
      realtime: realtime,
      inbox: inbox,
      child: const MaterialApp(
        home: AskBackChatScreen(conversationId: conversationId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return remote;
}

void main() {
  testWidgets('shows the header, the rule, their reason and the composer', (
    tester,
  ) async {
    await _open(
      tester,
      current: conversation(messagesLeft: 2),
      history: [message(1, mine: true)],
    );

    expect(find.text('Anonymous friend'), findsOneWidget);
    expect(find.text('Picked "A"'), findsOneWidget);
    // Rule banner above the thread; only the two turn tags sit in the list.
    expect(find.textContaining('1 question'), findsOneWidget);
    expect(find.text('THEIR REASON'), findsOneWidget);
    expect(find.text('Clearer'), findsOneWidget);
    expect(find.textContaining('Sent ·'), findsOneWidget);
    expect(find.text('2 messages left with this person'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Send'), findsOneWidget);
  });

  testWidgets('the reason giver sees "MY REASON" on the right', (tester) async {
    await _open(
      tester,
      current: conversation(
        myRole: 'voter',
        turn: AskBackTurn.them,
        canSend: false,
      ),
      history: [message(1)],
    );

    expect(find.text('MY REASON'), findsOneWidget);
    expect(find.text('THEIR REASON'), findsNothing);

    final reasonLeft = tester.getTopLeft(find.text('MY REASON')).dx;
    final reasonRight = tester.getTopRight(find.text('MY REASON')).dx;
    // Label sits on the right half of the screen for the reason giver.
    expect(reasonLeft, greaterThan(400));
    expect(reasonRight, greaterThan(reasonLeft));
  });

  testWidgets('has no mute, close or unblock controls', (tester) async {
    await _open(tester, history: [message(1, mine: true)]);

    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.textContaining('Mute'), findsNothing);
    expect(find.textContaining('Close'), findsNothing);
    expect(find.text('Unblock'), findsNothing);
  });

  testWidgets('the caption is hidden when the plan has no limit', (
    tester,
  ) async {
    await _open(tester, history: [message(1, mine: true)]);

    expect(find.textContaining('left with this person'), findsNothing);
  });

  testWidgets('a reply on my turn shows the green "your turn" pill', (
    tester,
  ) async {
    await _open(
      tester,
      current: conversation(turn: AskBackTurn.me),
      history: [message(1, mine: true), message(2)],
    );

    expect(find.text('They replied · your turn'), findsOneWidget);
  });

  testWidgets('waiting for the other person replaces the input', (
    tester,
  ) async {
    await _open(
      tester,
      current: conversation(turn: AskBackTurn.them, canSend: false),
      history: [message(1, mine: true)],
    );

    expect(find.text('Waiting for their reply'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('They replied · your turn'), findsNothing);
    expect(find.text('You can ask again once they reply.'), findsOneWidget);
  });

  testWidgets('sending a message swaps the composer to waiting immediately', (
    tester,
  ) async {
    await _open(
      tester,
      current: conversation(
        messagesLeft: 3,
        turn: AskBackTurn.me,
        canSend: true,
      ),
      history: const [],
    );

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Why that option?');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    // One frame only — do not wait for the network; UI must flip now.
    await tester.pump();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Waiting for their reply'), findsOneWidget);
    expect(find.textContaining('2 messages left'), findsNothing);
    expect(find.text('You can ask again once they reply.'), findsOneWidget);
  });

  testWidgets('the thread starts at the top, not above the composer', (
    tester,
  ) async {
    await _open(
      tester,
      current: conversation(turn: AskBackTurn.them, canSend: false),
      history: [message(1, mine: true)],
    );

    final reasonTop = tester.getTopLeft(find.text('THEIR REASON')).dy;
    final barTop = tester.getTopLeft(find.text('Waiting for their reply')).dy;
    // With one message the reason sits right under the app bar, far from the
    // bottom bar.
    expect(reasonTop, lessThan(150));
    expect(barTop - reasonTop, greaterThan(300));
  });

  testWidgets('no tag before the first message, or when it is my turn to ask', (
    tester,
  ) async {
    await _open(tester, current: conversation(), history: const []);

    expect(find.text('They replied · your turn'), findsNothing);
    expect(find.text('You can ask again once they reply.'), findsNothing);
  });

  testWidgets('an expired plan pauses the chat', (tester) async {
    await _open(
      tester,
      current: conversation(canSend: false, isPaused: true),
      history: [message(1, mine: true)],
    );

    expect(find.text('Chat paused'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a finished chat is ended, and Reopen shows only when allowed', (
    tester,
  ) async {
    await _open(
      tester,
      current: conversation(
        status: AskBackStatus.closed,
        canSend: false,
        canReopen: true,
      ),
    );

    expect(find.text('Chat ended'), findsOneWidget);
    expect(find.text('Reopen'), findsOneWidget);
  });

  testWidgets('a finished chat that cannot be reopened has no Reopen', (
    tester,
  ) async {
    await _open(
      tester,
      current: conversation(
        status: AskBackStatus.closed,
        canSend: false,
        turn: AskBackTurn.them,
      ),
    );

    expect(find.text('Chat ended'), findsOneWidget);
    expect(find.text('Reopen'), findsNothing);
  });

  testWidgets('when the free ask back is used, the unlock CTA shows', (
    tester,
  ) async {
    await _open(
      tester,
      current: conversation(
        canSend: false,
        turn: AskBackTurn.done,
        waitingReplies: 33,
      ),
      history: [message(1, mine: true), message(2)],
    );

    expect(find.text('Your free ask back is used'), findsOneWidget);
    expect(find.textContaining('all 33 waiting replies'), findsOneWidget);
    expect(find.text('Unlock now'), findsOneWidget);
    expect(find.byKey(const ValueKey('free-ask-unlock')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byKey(const ValueKey('free-ask-unlock')));
    await tester.pumpAndSettle();
    expect(find.text('See what they really think'), findsOneWidget);
  });

  testWidgets(
    'when the card is already unlocked, limit bar offers Yakku plans',
    (tester) async {
      await _open(
        tester,
        current: conversation(
          canSend: false,
          turn: AskBackTurn.done,
          waitingReplies: 12,
        ),
        history: [message(1, mine: true), message(2)],
        cardAccess: const AskBackAccess(
          unlocked: true,
          paused: false,
          planCode: 'yakku_lite',
          planName: 'Yakku Lite',
          planExpired: false,
          canUnlock: false,
          reasonsRevealed: true,
          unlockSource: 'purchase',
        ),
      );

      expect(find.text('Want more ask backs?'), findsOneWidget);
      expect(find.text('Show Yakku plans'), findsOneWidget);
      expect(find.text('Unlock now'), findsNothing);
      expect(find.textContaining('Unlock this card \u00B7'), findsNothing);
    },
  );

  testWidgets(
    'when tickets remain, limit bar offers Unlock this card with ticket count',
    (tester) async {
      await _open(
        tester,
        current: conversation(
          canSend: false,
          turn: AskBackTurn.done,
          waitingReplies: 8,
        ),
        history: [message(1, mine: true), message(2)],
        cardAccess: const AskBackAccess(
          unlocked: false,
          paused: false,
          planCode: 'yakku_lite',
          planName: 'Yakku Lite',
          planExpired: false,
          canUnlock: true,
          reasonsRevealed: true,
          ticketsLeft: 3,
        ),
      );

      expect(find.text('Unlock this card'), findsOneWidget);
      expect(
        find.text('Unlock this card \u00B7 3 tickets left'),
        findsOneWidget,
      );
      expect(find.text('Unlock now'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('free-ask-unlock')));
      await tester.pumpAndSettle();
      expect(find.text('Not now'), findsOneWidget);
      expect(find.text('See what they really think'), findsNothing);
    },
  );

  testWidgets('blocking asks what happened, reports, and ends the chat', (
    tester,
  ) async {
    final remote = await _open(tester, history: [message(1, mine: true)]);

    await tester.tap(find.byTooltip('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Block'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('block-row')));
    await tester.pumpAndSettle();
    expect(find.text('What happened?'), findsOneWidget);
    for (final reason in [
      'Harassing me',
      'Trying to find out who I am',
      'Sexual messages',
      'Hate or slurs',
      'Spam or scam',
      'Something else',
    ]) {
      expect(find.text(reason), findsOneWidget);
    }

    // Blocking always reports, so a reason has to be picked first.
    final confirm = find.byKey(const ValueKey('block-confirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.tap(find.text('Harassing me'));
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(remote.blockReasons, ['Harassing me']);
    expect(find.text('Anonymous friend · blocked'), findsOneWidget);
    // The disabled bar says it; the thread has no tag for it.
    expect(find.text('Chat ended'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('Report'), findsNothing);
  });

  testWidgets('Back and Cancel leave the chat untouched', (tester) async {
    final remote = await _open(tester, history: [message(1, mine: true)]);

    await tester.tap(find.byTooltip('Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('block-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Report'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(remote.blockReasons, isEmpty);
    expect(find.text('Anonymous friend'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  group('unlock sheet', () {
    AskBackAccess access({
      bool canUnlock = false,
      String code = 'free',
      int? tickets,
      bool expired = false,
    }) => AskBackAccess(
      unlocked: false,
      paused: false,
      planCode: code,
      planName: code == 'free' ? 'Free' : 'Yakku Lite',
      planExpired: expired,
      canUnlock: canUnlock,
      ticketsLeft: tickets,
      planExpiresAt: expired || code == 'free'
          ? null
          : DateTime.utc(2026, 11, 25),
    );

    Future<Future<bool?>> show(
      WidgetTester tester,
      AskBackAccess data,
      Future<AskBackAccess> Function() unlock,
    ) async {
      late Future<bool?> result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => result = showAskBackUnlockSheet(
                context,
                access: data,
                unlock: unlock,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('a plan with tickets unlocks the card', (tester) async {
      var unlocked = 0;
      final data = access(canUnlock: true, code: 'yakku_lite', tickets: 2);
      final result = await show(tester, data, () async {
        unlocked++;
        return data;
      });

      expect(find.textContaining('2 tickets left'), findsOneWidget);
      await tester.tap(find.text('Unlock card'));
      await tester.pumpAndSettle();

      expect(unlocked, 1);
      expect(await result, isTrue);
    });

    testWidgets('the free plan explains and offers no unlock', (tester) async {
      final result = await show(tester, access(), () async => access());

      expect(find.textContaining('one ask back per card'), findsOneWidget);
      expect(find.text('Unlock card'), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });

    testWidgets('an ended plan says so', (tester) async {
      await show(
        tester,
        access(code: 'yakku_lite', expired: true),
        () async => access(),
      );

      expect(find.text('Your plan has ended'), findsOneWidget);
      expect(find.text('Unlock card'), findsNothing);
    });
  });
}
