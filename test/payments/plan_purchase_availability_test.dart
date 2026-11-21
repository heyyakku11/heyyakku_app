import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';

YakkuPlan plan({
  required String code,
  required String name,
  int priceMinor = 9900,
  int? durationDays,
  int? unlockTickets,
  int? askBackMessageLimit,
}) {
  return YakkuPlan(
    id: code,
    code: code,
    name: name,
    priceMinor: priceMinor,
    currency: 'INR',
    durationDays: durationDays,
    unlockTickets: unlockTickets,
    askBackMessageLimit: askBackMessageLimit,
  );
}

void main() {
  final catalog = [
    plan(code: YakkuPlan.freeCode, name: 'Free', priceMinor: 0),
    plan(
      code: YakkuPlan.thisCardCode,
      name: 'This card',
      priceMinor: 4900,
      unlockTickets: 1,
      askBackMessageLimit: 1,
    ),
    plan(
      code: YakkuPlan.liteCode,
      name: 'Yakku Lite',
      priceMinor: 9900,
      durationDays: 7,
      unlockTickets: 3,
      askBackMessageLimit: 3,
    ),
    plan(
      code: YakkuPlan.loveCode,
      name: 'Yakku Love',
      priceMinor: 29900,
      durationDays: 30,
      askBackMessageLimit: null,
    ),
  ];

  group('effectivePlanCode', () {
    test('expired plan falls back to Free', () {
      expect(
        effectivePlanCode(code: YakkuPlan.loveCode, isExpired: true),
        YakkuPlan.freeCode,
      );
      expect(
        effectivePlanCode(code: YakkuPlan.liteCode, isExpired: true),
        YakkuPlan.freeCode,
      );
      expect(
        effectivePlanCode(code: null, isExpired: false),
        YakkuPlan.freeCode,
      );
    });

    test('active codes stay as-is', () {
      expect(
        effectivePlanCode(code: YakkuPlan.liteCode, isExpired: false),
        YakkuPlan.liteCode,
      );
      expect(
        effectivePlanCode(code: YakkuPlan.loveCode, isExpired: false),
        YakkuPlan.loveCode,
      );
    });

    test('expired Love can buy Lite again via availability', () {
      final effective = effectivePlanCode(
        code: YakkuPlan.loveCode,
        isExpired: true,
      );
      expect(
        planPurchaseAvailability(
          plan: catalog[2],
          effectiveCode: effective,
        ),
        PlanPurchaseAvailability.available,
      );
      expect(
        planPurchaseAvailability(
          plan: catalog[3],
          effectiveCode: effective,
        ),
        PlanPurchaseAvailability.available,
      );
    });
  });

  group('planPurchaseAvailability', () {
    test('free can buy lite, love, and this_card', () {
      expect(
        planPurchaseAvailability(
          plan: catalog[2],
          effectiveCode: YakkuPlan.freeCode,
        ),
        PlanPurchaseAvailability.available,
      );
      expect(
        planPurchaseAvailability(
          plan: catalog[3],
          effectiveCode: YakkuPlan.freeCode,
        ),
        PlanPurchaseAvailability.available,
      );
      expect(
        planPurchaseAvailability(
          plan: catalog[1],
          effectiveCode: YakkuPlan.freeCode,
        ),
        PlanPurchaseAvailability.available,
      );
    });

    test('lite marks lite as current and love as available', () {
      expect(
        planPurchaseAvailability(
          plan: catalog[2],
          effectiveCode: YakkuPlan.liteCode,
        ),
        PlanPurchaseAvailability.current,
      );
      expect(
        planPurchaseAvailability(
          plan: catalog[3],
          effectiveCode: YakkuPlan.liteCode,
        ),
        PlanPurchaseAvailability.available,
      );
    });

    test('love blocks downgrade to lite', () {
      expect(
        planPurchaseAvailability(
          plan: catalog[3],
          effectiveCode: YakkuPlan.loveCode,
        ),
        PlanPurchaseAvailability.current,
      );
      expect(
        planPurchaseAvailability(
          plan: catalog[2],
          effectiveCode: YakkuPlan.loveCode,
        ),
        PlanPurchaseAvailability.downgrade,
      );
    });
  });

  group('purchasablePlansForSheet', () {
    test('without card context omits this_card and free', () {
      final offers = purchasablePlansForSheet(
        catalog: catalog,
        includeThisCard: false,
      );
      expect(offers.map((p) => p.code), [
        YakkuPlan.liteCode,
        YakkuPlan.loveCode,
      ]);
    });

    test('with card context includes this_card first', () {
      final offers = purchasablePlansForSheet(
        catalog: catalog,
        includeThisCard: true,
      );
      expect(offers.map((p) => p.code), [
        YakkuPlan.thisCardCode,
        YakkuPlan.liteCode,
        YakkuPlan.loveCode,
      ]);
    });

    test('prices and details come from catalog fields', () {
      final lite = catalog[2];
      expect(lite.formattedPrice, '₹99');
      expect(lite.detailLine, '3 cards · 7 days');
      expect(lite.purchaseButtonLabel, 'Get Yakku Lite · ₹99');
      expect(catalog[1].detailLine, 'One card');
    });
  });
}
