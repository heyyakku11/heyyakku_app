import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/widgets/yakku_plans_sheet.dart';

import '../helpers/app_scope_fakes.dart';

class _PlansUserRemote extends Fake implements UserRemoteDataSource {
  _PlansUserRemote({required this.plans});

  final List<YakkuPlan> plans;
  int listCalls = 0;

  @override
  Future<List<YakkuPlan>> listPlans() async {
    listCalls += 1;
    return plans;
  }
}

class _FailingPlansRemote extends Fake implements UserRemoteDataSource {
  @override
  Future<List<YakkuPlan>> listPlans() async {
    throw Exception('offline');
  }
}

class _AskBackRemote extends Fake implements AskBackRemoteDataSource {
  _AskBackRemote({this.cardAccess});

  AskBackAccess? cardAccess;
  int cardAccessCalls = 0;

  @override
  Future<AskBackAccess> getCardAccess(
    String contentType,
    String contentId,
  ) async {
    cardAccessCalls += 1;
    return cardAccess ??
        const AskBackAccess(
          unlocked: false,
          paused: false,
          planCode: 'free',
          planName: 'Free',
          planExpired: false,
          canUnlock: false,
          reasonsRevealed: false,
        );
  }
}

class _Realtime extends Fake implements AskBackRealtime {}

List<YakkuPlan> sampleCatalog() => const [
      YakkuPlan(
        id: 'free',
        code: YakkuPlan.freeCode,
        name: 'Free',
        priceMinor: 0,
        currency: 'INR',
      ),
      YakkuPlan(
        id: 'card',
        code: YakkuPlan.thisCardCode,
        name: 'This card',
        priceMinor: 4900,
        currency: 'INR',
        unlockTickets: 1,
        askBackMessageLimit: 1,
      ),
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

Future<_AskBackRemote> pumpSheet(
  WidgetTester tester, {
  required UserRemoteDataSource userRemote,
  String? contentType,
  String? contentId,
  bool? includeThisCardOverride,
  AskBackAccess? cardAccess,
  UserPlanResponse? currentPlan,
  List<YakkuPlan>? catalog,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final askBack = _AskBackRemote(cardAccess: cardAccess);
  final realtime = _Realtime();
  final inbox = AskBackInboxController(remote: askBack, realtime: realtime);

  await tester.pumpWidget(
    testAppScope(
      askBack: askBack,
      realtime: realtime,
      inbox: inbox,
      userRemote: userRemote,
      child: MaterialApp(
        home: Scaffold(
          body: YakkuPlansSheet(
            contentType: contentType,
            contentId: contentId,
            includeThisCardOverride: includeThisCardOverride,
            initialCurrentPlan: currentPlan,
            initialCatalog: catalog,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return askBack;
}

void main() {
  testWidgets('loads catalog prices from backend fields', (tester) async {
    final remote = _PlansUserRemote(plans: sampleCatalog());
    await pumpSheet(tester, userRemote: remote);

    expect(find.text('Yakku Lite'), findsWidgets);
    expect(find.text('Yakku Love'), findsWidgets);
    expect(find.text('₹99'), findsOneWidget);
    expect(find.text('₹299'), findsOneWidget);
    expect(find.textContaining('Get Yakku Lite'), findsOneWidget);
    expect(find.text('This card'), findsNothing);
    expect(remote.listCalls, 1);
  });

  testWidgets('includes this_card when content context is locked', (
    tester,
  ) async {
    final remote = _PlansUserRemote(plans: sampleCatalog());
    final askBack = await pumpSheet(
      tester,
      userRemote: remote,
      contentType: 'poll',
      contentId: 'poll-1',
      catalog: sampleCatalog(),
      cardAccess: const AskBackAccess(
        unlocked: false,
        paused: false,
        planCode: 'free',
        planName: 'Free',
        planExpired: false,
        canUnlock: false,
        reasonsRevealed: false,
      ),
    );

    expect(find.text('This card'), findsOneWidget);
    expect(find.text('₹49'), findsOneWidget);
    expect(askBack.cardAccessCalls, 1);
  });

  testWidgets('omits this_card when the card is already unlocked', (
    tester,
  ) async {
    final remote = _PlansUserRemote(plans: sampleCatalog());
    await pumpSheet(
      tester,
      userRemote: remote,
      contentType: 'poll',
      contentId: 'poll-1',
      catalog: sampleCatalog(),
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

    expect(find.text('This card'), findsNothing);
    expect(find.text('Yakku Lite'), findsWidgets);
    expect(find.text('Yakku Love'), findsWidgets);
  });

  testWidgets('keeps this_card when unlock is paused', (tester) async {
    final remote = _PlansUserRemote(plans: sampleCatalog());
    await pumpSheet(
      tester,
      userRemote: remote,
      contentType: 'poll',
      contentId: 'poll-1',
      catalog: sampleCatalog(),
      cardAccess: const AskBackAccess(
        unlocked: true,
        paused: true,
        planCode: 'yakku_lite',
        planName: 'Yakku Lite',
        planExpired: true,
        canUnlock: false,
        reasonsRevealed: false,
        unlockSource: 'plan',
      ),
    );

    expect(find.text('This card'), findsOneWidget);
  });

  testWidgets('includeThisCardOverride false skips access lookup', (
    tester,
  ) async {
    final remote = _PlansUserRemote(plans: sampleCatalog());
    final askBack = await pumpSheet(
      tester,
      userRemote: remote,
      contentType: 'poll',
      contentId: 'poll-1',
      includeThisCardOverride: false,
      catalog: sampleCatalog(),
    );

    expect(find.text('This card'), findsNothing);
    expect(askBack.cardAccessCalls, 0);
  });

  testWidgets('disables buy when current plan is already Love', (tester) async {
    final remote = _PlansUserRemote(plans: sampleCatalog());
    await pumpSheet(
      tester,
      userRemote: remote,
      catalog: sampleCatalog(),
      currentPlan: const UserPlanResponse(
        id: 'love',
        code: YakkuPlan.loveCode,
        name: 'Yakku Love',
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.text('Current plan'), findsWidgets);
  });

  testWidgets('expired Love falls back so Lite is purchasable', (tester) async {
    final remote = _PlansUserRemote(plans: sampleCatalog());
    await pumpSheet(
      tester,
      userRemote: remote,
      catalog: sampleCatalog(),
      currentPlan: UserPlanResponse(
        id: 'love',
        code: YakkuPlan.loveCode,
        name: 'Yakku Love',
        expiresAt: DateTime.utc(2026, 10, 1),
        isExpired: true,
      ),
    );

    expect(find.textContaining('Get Yakku Lite'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('shows retry when catalog fails', (tester) async {
    await pumpSheet(tester, userRemote: _FailingPlansRemote());
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('Could not load plans'), findsOneWidget);
  });
}
