import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';
import 'package:yakku/presentation/screens/profile/widgets/profile_plan_card.dart';

YakkuPlan lite() => const YakkuPlan(
      id: 'lite',
      code: YakkuPlan.liteCode,
      name: 'Yakku Lite',
      priceMinor: 9900,
      currency: 'INR',
      durationDays: 7,
      unlockTickets: 3,
    );

YakkuPlan love() => const YakkuPlan(
      id: 'love',
      code: YakkuPlan.loveCode,
      name: 'Yakku Love',
      priceMinor: 29900,
      currency: 'INR',
      durationDays: 30,
    );

Future<void> pumpCard(
  WidgetTester tester, {
  required UserPlanResponse? current,
  required List<YakkuPlan> upgrades,
  VoidCallback? onSeePlans,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProfilePlanCard(
            currentPlan: current,
            upgradePlans: upgrades,
            onSeePlans: onSeePlans ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('free user sees both mini-cards and badge', (tester) async {
    await pumpCard(
      tester,
      current: const UserPlanResponse(
        id: 'free',
        code: YakkuPlan.freeCode,
        name: 'Free',
      ),
      upgrades: [lite(), love()],
    );

    expect(find.text('YOUR PLAN · FREE'), findsOneWidget);
    expect(find.text('Yakku Lite'), findsOneWidget);
    expect(find.text('Yakku Love'), findsOneWidget);
    expect(find.text('₹99'), findsOneWidget);
    expect(find.text('₹299'), findsOneWidget);
    expect(find.text('See plans'), findsOneWidget);
    expect(find.text('Every reason'), findsOneWidget);
  });

  testWidgets('empty upgrades renders nothing', (tester) async {
    await pumpCard(
      tester,
      current: const UserPlanResponse(
        id: 'love',
        code: YakkuPlan.loveCode,
        name: 'Yakku Love',
      ),
      upgrades: const [],
    );

    expect(find.text('See plans'), findsNothing);
    expect(find.textContaining('YOUR PLAN'), findsNothing);
  });

  testWidgets('See plans CTA fires callback', (tester) async {
    var tapped = false;
    await pumpCard(
      tester,
      current: const UserPlanResponse(
        id: 'free',
        code: YakkuPlan.freeCode,
        name: 'Free',
      ),
      upgrades: [lite()],
      onSeePlans: () => tapped = true,
    );

    await tester.tap(find.text('See plans'));
    expect(tapped, isTrue);
  });
}
