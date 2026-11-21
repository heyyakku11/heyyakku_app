import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';
import 'package:yakku/data/repositories/personality_card_store.dart';
import 'package:yakku/presentation/payments/entitlement_refresh.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';

class _AuthStub extends Fake implements AuthController {
  @override
  bool get isLoggedIn => true;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _UserRemote implements UserRemoteDataSource {
  int getMeCount = 0;
  Object? error;
  UserPlanResponse? plan = UserPlanResponse(
    id: 'plan-love',
    code: 'yakku_love',
    name: 'Yakku Love',
    activatedAt: DateTime.utc(2026, 11, 1),
    expiresAt: DateTime.utc(2026, 12, 1),
    isExpired: false,
  );

  @override
  Future<UserProfileResponse> getMe() async {
    getMeCount += 1;
    if (error != null) throw error!;
    return UserProfileResponse(
      profile: const UserProfileDetails(anonymousName: 'Anon'),
      account: UserAccountDetails(
        status: 'Active',
        phoneNumber: '9999999999',
        currentPlan: plan,
      ),
      stats: const UserStatsDetails(
        cardsMade: 0,
        votesCast: 0,
        streak: UserStreakSummary(currentStreak: 0, longestStreak: 0),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AskBackRemote implements AskBackRemoteDataSource {
  int cardAccessCount = 0;
  String? lastContentType;
  String? lastContentId;
  AskBackAccess access = const AskBackAccess(
    unlocked: true,
    paused: false,
    planCode: 'yakku_love',
    planName: 'Yakku Love',
    planExpired: false,
    canUnlock: false,
    reasonsRevealed: true,
    unlockSource: 'plan',
    unlimitedMessages: true,
  );

  @override
  Future<AskBackAccess> getCardAccess(
    String contentType,
    String contentId,
  ) async {
    cardAccessCount += 1;
    lastContentType = contentType;
    lastContentId = contentId;
    return access;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Realtime extends Fake implements AskBackRealtime {}

class _PersonalityRemote extends Fake implements UserRemoteDataSource {
  @override
  Future<Never> getMyPersonalityCard() async {
    throw StateError('no personality card in test');
  }
}

void main() {
  test('afterFulfillment reloads plan and card access from backend', () async {
    final users = _UserRemote();
    final askBack = _AskBackRemote();
    final cards = PersonalityCardStore(
      remote: _PersonalityRemote(),
      auth: _AuthStub(),
    );
    final inbox = AskBackInboxController(
      remote: askBack,
      realtime: _Realtime(),
    );

    final snapshot = await EntitlementRefresh.afterFulfillment(
      userRemote: users,
      personalityCards: cards,
      askBack: askBack,
      askBackInbox: inbox,
      contentType: 'poll',
      contentId: 'poll-1',
    );

    expect(users.getMeCount, 1);
    expect(askBack.cardAccessCount, 1);
    expect(askBack.lastContentType, 'poll');
    expect(askBack.lastContentId, 'poll-1');
    expect(snapshot.currentPlan?.code, 'yakku_love');
    expect(snapshot.cardAccess?.reasonsRevealed, isTrue);
    expect(snapshot.cardAccess?.unlocked, isTrue);
  });

  test('skips card access when content context is missing', () async {
    final users = _UserRemote();
    final askBack = _AskBackRemote();
    final cards = PersonalityCardStore(
      remote: _PersonalityRemote(),
      auth: _AuthStub(),
    );

    final snapshot = await EntitlementRefresh.afterFulfillment(
      userRemote: users,
      personalityCards: cards,
      askBack: askBack,
    );

    expect(users.getMeCount, 1);
    expect(askBack.cardAccessCount, 0);
    expect(snapshot.cardAccess, isNull);
  });

  test('reflects Lite activation from backend getMe', () async {
    final users = _UserRemote()
      ..plan = UserPlanResponse(
        id: 'plan-lite',
        code: 'yakku_lite',
        name: 'Yakku Lite',
        activatedAt: DateTime.utc(2026, 11, 19),
        expiresAt: DateTime.utc(2026, 11, 26),
        isExpired: false,
      );
    final cards = PersonalityCardStore(
      remote: _PersonalityRemote(),
      auth: _AuthStub(),
    );

    final snapshot = await EntitlementRefresh.afterFulfillment(
      userRemote: users,
      personalityCards: cards,
    );

    expect(snapshot.currentPlan?.code, 'yakku_lite');
    expect(snapshot.currentPlan?.isExpired, isFalse);
  });

  test('Love superseding Lite comes only from backend snapshot', () async {
    final users = _UserRemote()
      ..plan = UserPlanResponse(
        id: 'plan-love',
        code: 'yakku_love',
        name: 'Yakku Love',
        activatedAt: DateTime.utc(2026, 11, 19),
        expiresAt: DateTime.utc(2026, 12, 19),
        isExpired: false,
      );
    final cards = PersonalityCardStore(
      remote: _PersonalityRemote(),
      auth: _AuthStub(),
    );

    final snapshot = await EntitlementRefresh.afterFulfillment(
      userRemote: users,
      personalityCards: cards,
    );

    expect(snapshot.currentPlan?.code, 'yakku_love');
  });

  test('expired Love snapshot is returned as-is for UI fallback', () async {
    final users = _UserRemote()
      ..plan = UserPlanResponse(
        id: 'plan-love',
        code: 'yakku_love',
        name: 'Yakku Love',
        activatedAt: DateTime.utc(2026, 10, 1),
        expiresAt: DateTime.utc(2026, 10, 31),
        isExpired: true,
      );
    final cards = PersonalityCardStore(
      remote: _PersonalityRemote(),
      auth: _AuthStub(),
    );

    final snapshot = await EntitlementRefresh.afterFulfillment(
      userRemote: users,
      personalityCards: cards,
    );

    expect(snapshot.currentPlan?.code, 'yakku_love');
    expect(snapshot.currentPlan?.isExpired, isTrue);
  });

  test('permanent card unlock remains from Ask Back access flags', () async {
    final users = _UserRemote();
    final askBack = _AskBackRemote()
      ..access = const AskBackAccess(
        unlocked: true,
        paused: false,
        planCode: 'yakku_free',
        planName: 'Free',
        planExpired: false,
        canUnlock: false,
        reasonsRevealed: true,
        unlockSource: 'this_card',
        unlimitedMessages: false,
      );
    final cards = PersonalityCardStore(
      remote: _PersonalityRemote(),
      auth: _AuthStub(),
    );

    final snapshot = await EntitlementRefresh.afterFulfillment(
      userRemote: users,
      personalityCards: cards,
      askBack: askBack,
      contentType: 'poll',
      contentId: 'poll-9',
    );

    expect(snapshot.cardAccess?.unlocked, isTrue);
    expect(snapshot.cardAccess?.unlockSource, 'this_card');
    expect(snapshot.cardAccess?.reasonsRevealed, isTrue);
  });

  test('getMe failure does not invent a local entitlement', () async {
    final users = _UserRemote()..error = Exception('offline');
    final cards = PersonalityCardStore(
      remote: _PersonalityRemote(),
      auth: _AuthStub(),
    );

    final snapshot = await EntitlementRefresh.afterFulfillment(
      userRemote: users,
      personalityCards: cards,
    );

    expect(users.getMeCount, 1);
    expect(snapshot.currentPlan, isNull);
    expect(snapshot.cardAccess, isNull);
  });
}
