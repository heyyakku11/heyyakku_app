import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/screens/profile/blocked_users_screen.dart';
import 'package:yakku/presentation/screens/profile/settings_screen.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

import '../helpers/app_scope_fakes.dart';
import 'ask_back_controllers_test.dart' show FakeRealtime, FakeRemote;

void main() {
  test('AskBackBlockItem parses without a user id field', () {
    final item = AskBackBlockItem.fromJson({
      'blockId': 'block-1',
      'anonymousName': 'Quiet Fox',
      'blockedAt': '2026-11-19T10:00:00Z',
      'sourceConversationId': 'conv-1',
    });
    expect(item.blockId, 'block-1');
    expect(item.anonymousName, 'Quiet Fox');
    expect(item.sourceConversationId, 'conv-1');
  });

  testWidgets('settings opens Blocked people and lists unblockable rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final remote = FakeRemote([]);
    remote.blocks = [
      AskBackBlockItem(
        blockId: 'block-1',
        anonymousName: 'Quiet Fox',
        blockedAt: DateTime.utc(2026, 11, 19),
        sourceConversationId: 'c1',
      ),
    ];
    final realtime = FakeRealtime();
    final inbox = AskBackInboxController(remote: remote, realtime: realtime);
    final navigatorKey = GlobalKey<NavigatorState>();
    AppToast.attach(navigatorKey);

    await tester.pumpWidget(
      testAppScope(
        askBack: remote,
        realtime: realtime,
        inbox: inbox,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blocked people'), findsOneWidget);
    await tester.tap(find.text('Blocked people'));
    await tester.pumpAndSettle();

    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('Quiet Fox'), findsOneWidget);
    expect(find.text('Unblock'), findsOneWidget);

    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();
    expect(find.text('Unblock?'), findsOneWidget);
    await tester.tap(find.text('Unblock').last);
    await tester.pumpAndSettle();
    // Toast timer (3s) must elapse before the test ends.
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Quiet Fox'), findsNothing);
    expect(find.text('No blocked people'), findsOneWidget);
    expect(remote.blocks, isEmpty);
  });

  testWidgets('empty blocked list shows the empty state', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final remote = FakeRemote([]);
    final realtime = FakeRealtime();
    final inbox = AskBackInboxController(remote: remote, realtime: realtime);

    await tester.pumpWidget(
      testAppScope(
        askBack: remote,
        realtime: realtime,
        inbox: inbox,
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No blocked people'), findsOneWidget);
    expect(find.text('Unblock'), findsNothing);
  });
}
