import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';

void main() {
  test('parses unlockTickets and cardsUnlocked from getMe', () {
    final plan = UserPlanResponse.fromJson({
      'id': 'plan-1',
      'code': 'yakku_lite',
      'name': 'Yakku Lite',
      'activatedAt': '2026-11-14T00:00:00Z',
      'expiresAt': '2026-11-21T00:00:00Z',
      'isExpired': false,
      'unlockTickets': 3,
      'cardsUnlocked': 1,
    });

    expect(plan.unlockTickets, 3);
    expect(plan.cardsUnlocked, 1);
    expect(plan.isExpired, isFalse);
  });

  test('Love treats null unlockTickets as unlimited', () {
    final plan = UserPlanResponse.fromJson({
      'id': 'plan-2',
      'code': 'yakku_love',
      'name': 'Yakku Love',
      'isExpired': false,
      'cardsUnlocked': 7,
    });

    expect(plan.unlockTickets, isNull);
    expect(plan.cardsUnlocked, 7);
  });

  test('daysLeft ceils remaining whole days', () {
    final plan = UserPlanResponse(
      id: 'p',
      code: 'yakku_love',
      name: 'Yakku Love',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 30)),
    );
    expect(plan.daysLeft, 2);
  });
}
