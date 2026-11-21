import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_list_screen.dart';

import '../helpers/app_scope_fakes.dart';
import 'ask_back_controllers_test.dart' show FakeRealtime, FakeRemote;

AskBackListItem item({
  required String id,
  AskBackTurn turn = AskBackTurn.me,
  AskBackStatus status = AskBackStatus.active,
  bool isAsker = true,
  bool canUnblock = false,
  String title = 'Mirror Check',
  String option = 'Genuinely like you',
  String preview = 'Hello',
  bool previewMine = false,
}) {
  return AskBackListItem(
    id: id,
    status: status,
    myRole: isAsker ? 'asker' : 'voter',
    other: AskBackParticipant(
      anonymousName: isAsker ? 'Anonymous friend' : 'Quiet Fox',
    ),
    context: AskBackContext(
      contentType: title == 'Question' ? 'poll' : 'check',
      title: title,
      selectedOption: option,
    ),
    lastMessage: AskBackPreview(
      preview: preview,
      isMine: previewMine,
      createdAt: DateTime.utc(2026, 11, 1),
    ),
    lastActivityAt: DateTime.utc(2026, 11, 1),
    unreadCount: 0,
    turn: turn,
    canSend: turn == AskBackTurn.me && status == AskBackStatus.active,
    canUnblock: canUnblock,
  );
}

Future<void> open(WidgetTester tester, List<AskBackListItem> items) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final remote = FakeRemote([])..listItems = items;
  final realtime = FakeRealtime();
  final inbox = AskBackInboxController(remote: remote, realtime: realtime);
  await tester.pumpWidget(
    testAppScope(
      askBack: remote,
      realtime: realtime,
      inbox: inbox,
      child: const MaterialApp(home: AskBackListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows tabs and cards by turn', (tester) async {
    await open(tester, [
      item(id: '1', turn: AskBackTurn.me, preview: 'They replied'),
      item(
        id: '2',
        turn: AskBackTurn.me,
        isAsker: false,
        title: 'Mirror Check',
        preview: 'What small stuff?',
      ),
      item(
        id: '3',
        turn: AskBackTurn.them,
        title: 'Trust Check',
        preview: 'Who told you?',
        previewMine: true,
      ),
      item(
        id: '4',
        turn: AskBackTurn.done,
        title: 'Question',
        preview: 'The birthday one.',
      ),
    ]);

    expect(find.text('My ask backs'), findsOneWidget);
    expect(find.textContaining('1 question'), findsOneWidget);
    expect(find.text('All 4'), findsOneWidget);
    expect(find.text('Your turn 2'), findsOneWidget);
    expect(find.text('Waiting 1'), findsOneWidget);
    expect(find.text('Ended 1'), findsOneWidget);

    expect(find.textContaining('ACTIVE'), findsOneWidget);
    expect(find.textContaining('ENDED'), findsOneWidget);
    expect(find.text('Your turn'), findsNWidgets(2));
    expect(find.text('Waiting for their reply'), findsOneWidget);
    expect(find.text('Chat ended'), findsOneWidget);
    expect(find.textContaining('YOUR MIRROR CHECK'), findsOneWidget);
    expect(find.textContaining('THEIR MIRROR CHECK'), findsOneWidget);
    expect(find.text('Someone you answered'), findsOneWidget);
  });

  testWidgets('the Waiting tab only shows waiting chats', (tester) async {
    await open(tester, [
      item(id: '1', turn: AskBackTurn.me),
      item(id: '2', turn: AskBackTurn.them, previewMine: true),
      item(id: '3', turn: AskBackTurn.done),
    ]);

    await tester.tap(find.text('Waiting 1'));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for their reply'), findsOneWidget);
    expect(find.text('Your turn'), findsNothing);
    expect(find.text('Chat ended'), findsNothing);
    expect(find.textContaining('ACTIVE'), findsNothing);
  });

  testWidgets('blocked chats tag Block when I blocked and Blocked when they did', (
    tester,
  ) async {
    await open(tester, [
      item(
        id: '1',
        status: AskBackStatus.blocked,
        turn: AskBackTurn.done,
        canUnblock: true,
        title: 'Question',
        preview: 'I blocked them',
      ),
      item(
        id: '2',
        status: AskBackStatus.blocked,
        turn: AskBackTurn.done,
        canUnblock: false,
        title: 'Trust Check',
        preview: 'They blocked me',
      ),
    ]);

    await tester.tap(find.textContaining('Ended'));
    await tester.pumpAndSettle();

    expect(find.text('Block'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
  });
}
