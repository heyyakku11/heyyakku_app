import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';

YakkuPlan plan({
  required String code,
  required String name,
  int priceMinor = 0,
  int? durationDays,
  int? unlockTickets,
}) {
  return YakkuPlan(
    id: code,
    code: code,
    name: name,
    priceMinor: priceMinor,
    currency: 'INR',
    durationDays: durationDays,
    unlockTickets: unlockTickets,
  );
}

void main() {
  final catalog = [
    plan(code: YakkuPlan.freeCode, name: 'Free'),
    plan(
      code: YakkuPlan.liteCode,
      name: 'Yakku Lite',
      priceMinor: 9900,
      durationDays: 7,
      unlockTickets: 3,
    ),
    plan(
      code: YakkuPlan.loveCode,
      name: 'Yakku Love',
      priceMinor: 29900,
      durationDays: 30,
    ),
  ];

  group('effectivePlanCode', () {
    test('expired paid plan becomes free', () {
      expect(
        effectivePlanCode(code: YakkuPlan.liteCode, isExpired: true),
        YakkuPlan.freeCode,
      );
    });

    test('missing code becomes free', () {
      expect(effectivePlanCode(code: null, isExpired: false), YakkuPlan.freeCode);
      expect(effectivePlanCode(code: '', isExpired: false), YakkuPlan.freeCode);
    });

    test('keeps active paid code', () {
      expect(
        effectivePlanCode(code: YakkuPlan.loveCode, isExpired: false),
        YakkuPlan.loveCode,
      );
    });
  });

  group('plansAboveCurrent', () {
    test('free sees lite and love', () {
      final above = plansAboveCurrent(
        catalog: catalog,
        effectiveCode: YakkuPlan.freeCode,
      );
      expect(above.map((p) => p.code), [YakkuPlan.liteCode, YakkuPlan.loveCode]);
    });

    test('lite sees only love', () {
      final above = plansAboveCurrent(
        catalog: catalog,
        effectiveCode: YakkuPlan.liteCode,
      );
      expect(above.map((p) => p.code), [YakkuPlan.loveCode]);
    });

    test('love sees none', () {
      final above = plansAboveCurrent(
        catalog: catalog,
        effectiveCode: YakkuPlan.loveCode,
      );
      expect(above, isEmpty);
    });

    test('never includes free as an upsell', () {
      final above = plansAboveCurrent(
        catalog: catalog,
        effectiveCode: YakkuPlan.freeCode,
      );
      expect(above.any((p) => p.isFree), isFalse);
    });
  });

  group('planBadgeLabel', () {
    test('uses name when active', () {
      expect(
        planBadgeLabel(code: YakkuPlan.liteCode, name: 'Yakku Lite', isExpired: false),
        'YAKKU LITE',
      );
    });

    test('expired shows FREE', () {
      expect(
        planBadgeLabel(code: YakkuPlan.liteCode, name: 'Yakku Lite', isExpired: true),
        'FREE',
      );
    });
  });

  group('YakkuPlan display', () {
    test('formats price and detail line', () {
      final lite = catalog[1];
      expect(lite.formattedPrice, '₹99');
      expect(lite.detailLine, '3 cards · 7 days');

      final love = catalog[2];
      expect(love.formattedPrice, '₹299');
      expect(love.detailLine, 'Every card · 30 days');
    });
  });
}
