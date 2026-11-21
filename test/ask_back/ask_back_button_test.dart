import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/widgets/ask_back_button.dart';

import '../helpers/app_scope_fakes.dart';

class _PlansUserRemote extends Fake implements UserRemoteDataSource {
  @override
  Future<List<YakkuPlan>> listPlans() async {
    return const [
      YakkuPlan(
        id: 'lite',
        code: YakkuPlan.liteCode,
        name: 'Yakku Lite',
        priceMinor: 9900,
        currency: 'INR',
        durationDays: 7,
        unlockTickets: 3,
        askBackMessageLimit: 3,
      ),
      YakkuPlan(
        id: 'love',
        code: YakkuPlan.loveCode,
        name: 'Yakku Love',
        priceMinor: 29900,
        currency: 'INR',
        durationDays: 30,
      ),
    ];
  }
}

class _AskBackRemote extends Fake implements AskBackRemoteDataSource {
  String? unlockedVoteId;

  @override
  Future<AskBackAccess> unlock(String voteId) async {
    unlockedVoteId = voteId;
    return const AskBackAccess(
      unlocked: true,
      paused: false,
      planCode: 'yakku_lite',
      planName: 'Yakku Lite',
      planExpired: false,
      canUnlock: false,
      reasonsRevealed: true,
      ticketsLeft: 2,
      unlockSource: 'plan',
    );
  }
}

class _Realtime extends Fake implements AskBackRealtime {}

const _liteTickets = AskBackAccess(
  unlocked: false,
  paused: false,
  planCode: 'yakku_lite',
  planName: 'Yakku Lite',
  planExpired: false,
  canUnlock: true,
  reasonsRevealed: true,
  ticketsLeft: 3,
);

const _cardUnlocked = AskBackAccess(
  unlocked: true,
  paused: false,
  planCode: 'yakku_lite',
  planName: 'Yakku Lite',
  planExpired: false,
  canUnlock: false,
  reasonsRevealed: true,
  ticketsLeft: 2,
  unlockSource: 'plan',
);

void main() {
  testWidgets('locked ask back shows the padlock', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AskBackButton(voteId: 'v1', locked: true, compact: true),
        ),
      ),
    );

    expect(find.text('Ask back'), findsOneWidget);
    expect(find.byIcon(Icons.reply_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('an open or started ask back has no closed padlock', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AskBackButton(voteId: 'v1', locked: false, compact: true),
        ),
      ),
    );

    expect(find.text('Ask back'), findsOneWidget);
    expect(find.byIcon(Icons.reply_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });

  testWidgets('unlocked card shows the open padlock', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AskBackButton(
            voteId: 'v1',
            locked: false,
            compact: true,
            cardAccess: _cardUnlocked,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });

  testWidgets('tapping a locked ask back without tickets opens plans', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final askBack = _AskBackRemote();
    final realtime = _Realtime();
    final inbox = AskBackInboxController(remote: askBack, realtime: realtime);

    await tester.pumpWidget(
      testAppScope(
        askBack: askBack,
        realtime: realtime,
        inbox: inbox,
        userRemote: _PlansUserRemote(),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AskBackButton(voteId: 'v1', locked: true, compact: true),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ask back'));
    await tester.pumpAndSettle();

    expect(find.text('See what they really think'), findsOneWidget);
    expect(find.textContaining('Get Yakku Lite'), findsOneWidget);
  });

  testWidgets('tapping a locked ask back with tickets opens unlock sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final askBack = _AskBackRemote();
    final realtime = _Realtime();
    final inbox = AskBackInboxController(remote: askBack, realtime: realtime);

    await tester.pumpWidget(
      testAppScope(
        askBack: askBack,
        realtime: realtime,
        inbox: inbox,
        userRemote: _PlansUserRemote(),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AskBackButton(
                voteId: 'v1',
                locked: true,
                compact: true,
                cardAccess: _liteTickets,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ask back'));
    await tester.pumpAndSettle();

    expect(find.text('See what they really think'), findsNothing);
    expect(find.textContaining('Unlock'), findsWidgets);
    expect(find.text('Not now'), findsOneWidget);
  });
}
