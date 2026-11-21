import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/auth/auth_token_store.dart';
import 'package:yakku/core/auth/login_auth_service.dart';
import 'package:yakku/core/auth/user_preferences.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';
import 'package:yakku/core/device/device_registration_service.dart';
import 'package:yakku/core/payments/payment_flow_controller.dart';
import 'package:yakku/core/payments/pending_payment_store.dart';
import 'package:yakku/core/payments/pending_purchase_intent.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/core/router/app_router.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/datasources/check_remote_data_source.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/datasources/payment_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/auth/verify_otp_data.dart';
import 'package:yakku/data/models/auth/verify_otp_request_model.dart';
import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/data/repositories/draft_poll_store.dart';
import 'package:yakku/data/repositories/mock_poll_repository.dart';
import 'package:yakku/data/repositories/personality_card_store.dart';
import 'package:yakku/data/repositories/poll_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/screens/personality/shared_personality_screen.dart';

const _code = 'aB3dE5gH7k';
const _otherCode = 'Zq9xW2mN4p';

/// Passed explicitly: the default web host depends on the build's ENV.
const _web = 'https://heyyakku-web.vercel.app';

const _traits = [
  PersonalityTrait(id: 't1', name: 'Kind'),
  PersonalityTrait(id: 't2', name: 'Funny'),
  PersonalityTrait(id: 't3', name: 'Loyal'),
  PersonalityTrait(id: 't4', name: 'Bold'),
];

SharedPersonalityCard _card({
  String shareCode = _code,
  PersonalityCardStatus status = PersonalityCardStatus.collecting,
  bool isOwner = false,
  bool hasVoted = false,
  bool canVote = true,
}) => SharedPersonalityCard(
  shareCode: shareCode,
  ownerAnonymousName: 'Quiet Fox',
  status: status,
  isOwner: isOwner,
  hasVoted: hasVoted,
  canVote: canVote,
  totalVotes: 2,
  requiredVotes: 5,
);

DioException _http(int status, {String? code}) => DioException(
  type: DioExceptionType.badResponse,
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: {
      'success': false,
      'message': 'nope',
      if (code != null)
        'errors': [
          {'code': code, 'message': 'nope'},
        ],
    },
  ),
);

class _FakeUserRemote extends Fake implements UserRemoteDataSource {
  _FakeUserRemote(this.onGet);

  final Future<SharedPersonalityCard> Function(String shareCode) onGet;
  final requested = <String>[];
  final votes = <(String, List<String>)>[];
  Object? voteError;

  @override
  Future<SharedPersonalityCard> getSharedPersonalityCard(String shareCode) {
    requested.add(shareCode);
    return onGet(shareCode);
  }

  @override
  Future<List<PersonalityTrait>> getPersonalityTraits() async => _traits;

  @override
  Future<PersonalityVoteResult> votePersonalityCard(
    String shareCode,
    List<String> traitIds,
  ) async {
    votes.add((shareCode, traitIds));
    final error = voteError;
    if (error != null) throw error;
    return PersonalityVoteResult(
      shareCode: shareCode,
      cardStatus: PersonalityCardStatus.collecting,
      totalVotes: 3,
      requiredVotes: 5,
    );
  }
}

class _FakePrefs extends Fake implements UserPreferences {
  @override
  Future<void> setPhoneNumber(String phoneNumber) async {}

  @override
  Future<void> setDisplayName(String displayName) async {}

  @override
  Future<void> setIsUserLogged(bool value) async {}

  @override
  Future<void> setCommunityNotifyRequested(bool value) async {}

  @override
  Future<void> setHasCompletedOnboarding(bool value) async {}

  @override
  Future<void> clearAuth() async {}
}

class _FakeTokens extends Fake implements AuthTokenStore {
  @override
  String? get accessToken => null;

  @override
  String? get refreshToken => null;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> clear() async {}
}

class _FakeAuthRemote extends Fake implements AuthRemoteDataSource {
  @override
  Future<VerifyOtpData> verifyOtp(VerifyOtpRequestModel request) async {
    return const VerifyOtpData(
      purpose: 'Login',
      accountRestored: false,
      user: VerifyOtpUser(anonymousName: 'Tester'),
      auth: VerifyOtpAuth(
        accessToken: 'a',
        refreshToken: 'r',
        accessTokenExpiresInSeconds: 900,
        refreshTokenExpiresInSeconds: 3600,
      ),
    );
  }
}

AuthController _auth({
  bool loggedIn = true,
  bool completedOnboarding = false,
}) => AuthController(
  userPreferences: _FakePrefs(),
  tokenStore: _FakeTokens(),
  authRemote: _FakeAuthRemote(),
  isUserLogged: loggedIn,
  hasCompletedOnboarding: completedOnboarding,
);

class _Scope extends StatelessWidget {
  const _Scope({required this.auth, required this.remote, required this.child});

  final AuthController auth;
  final _FakeUserRemote remote;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final payments = _FPayments();
    final pendingPayments = PendingPaymentStore(
      secureStorage: SecureStorageService.inMemory(),
    );
    final checkout = _FCheckout();
    return AppScope(
      themeController: _F1(),
      authController: auth,
      loginAuth: _F5(),
      backgroundApiWorker: _F6(),
      polls: _F7(),
      pollApi: _F20(),
      checkApi: _F14(),
      activityPolls: _F9(),
      userRemote: remote,
      payments: payments,
      pendingPayments: pendingPayments,
      pendingPurchase: _FPendingPurchase(),
      paymentFlow: PaymentFlowController(
        payments: payments,
        pendingPayments: pendingPayments,
        checkout: checkout,
      ),
      razorpayCheckout: checkout,
      notifications: _F15(),
      deviceRegistration: _F12(),
      draftPolls: _F13(),
      askBack: _F16(),
      askBackRealtime: _F17(),
      askBackInbox: _F18(),
      personalityCards: PersonalityCardStore(remote: remote, auth: auth),
      child: child,
    );
  }
}

class _F1 extends Fake implements ThemeController {}

class _F5 extends Fake implements LoginAuthService {}

class _F6 extends Fake implements BackgroundApiWorker {}

class _F7 extends Fake implements MockPollRepository {}

class _F9 extends Fake implements ActivityPollRepository {}

class _F15 extends Fake implements NotificationRemoteDataSource {}

class _F16 extends Fake implements AskBackRemoteDataSource {}

class _F17 extends Fake implements AskBackRealtime {}

class _F18 extends Fake implements AskBackInboxController {}

class _F12 extends Fake implements DeviceRegistrationService {}

class _F13 extends Fake implements DraftPollStore {}

class _F20 extends Fake implements PollApiRepository {}

class _FPayments extends Fake implements PaymentRemoteDataSource {}

class _FPendingPurchase extends Fake implements PendingPurchaseStore {}

class _FCheckout extends Fake implements RazorpayCheckoutService {
  @override
  bool get isOpening => false;

  @override
  bool get isSessionActive => false;
}

class _F14 extends CheckApiRepository {
  _F14() : super(_FakeCheckRemote());
}

class _FakeCheckRemote extends Fake implements CheckRemoteDataSource {
  @override
  Future<List<CheckResponse>> getChecks() async => const [];
}

void main() {
  group('personality links in PollDeepLink', () {
    test('shareCodeFromUrl accepts the canonical URL and keeps the case', () {
      expect(
        PollDeepLink.personalityShareCodeFromUrl(
          Uri.parse('https://heyyakku-web.vercel.app/personality/$_code?x=1#y'),
          webBaseUrl: _web,
        ),
        _code,
      );
    });

    for (final bad in [
      'http://heyyakku-web.vercel.app/personality/$_code',
      'https://evil.example.com/personality/$_code',
      'https://heyyakku-web.vercel.app.evil.com/personality/$_code',
      'https://heyyakku-web.vercel.app/vote/$_code',
      'https://heyyakku-web.vercel.app/personality/',
      'https://heyyakku-web.vercel.app/personality/not-a-code',
      'https://heyyakku-web.vercel.app/personality/$_code/extra',
      'yakku://personality/$_code',
    ]) {
      test('rejects $bad', () {
        expect(
          PollDeepLink.personalityShareCodeFromUrl(
            Uri.parse(bad),
            webBaseUrl: _web,
          ),
          isNull,
        );
      });
    }

    test('a poll link is not a personality link and vice versa', () {
      expect(
        PollDeepLink.shareCodeFromPath(Uri.parse('/personality/$_code')),
        isNull,
      );
      expect(
        PollDeepLink.personalityShareCodeFromPath(Uri.parse('/vote/$_code')),
        isNull,
      );
      expect(
        PollDeepLink.fromPath(Uri.parse('/vote/$_code')),
        const AppDeepLink(AppDeepLinkKind.poll, _code),
      );
      expect(
        PollDeepLink.fromPath(Uri.parse('/personality/$_code')),
        const AppDeepLink(AppDeepLinkKind.personality, _code),
      );
    });

    test('safeReturnPath keeps in-app poll and personality paths only', () {
      expect(
        PollDeepLink.safeReturnPath('/personality/$_code'),
        '/personality/$_code',
      );
      expect(PollDeepLink.safeReturnPath('/vote/$_code'), '/vote/$_code');
      expect(PollDeepLink.safeReturnPath('/main'), isNull);
      expect(
        PollDeepLink.safeReturnPath('https://evil.com/personality/$_code'),
        isNull,
      );
      expect(
        PollDeepLink.safeReturnPath('//evil.com/personality/$_code'),
        isNull,
      );
    });
  });

  group('router + SharedPersonalityScreen', () {
    Future<GoRouter> open(
      WidgetTester tester,
      _FakeUserRemote remote, {
      bool loggedIn = true,
      bool completedOnboarding = false,
      String location = '/personality/$_code',
      AuthController? auth,
    }) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final authController =
          auth ??
          _auth(loggedIn: loggedIn, completedOnboarding: completedOnboarding);
      final router = AppRouter.create(
        authController,
        navigatorKey: GlobalKey<NavigatorState>(),
      )..go(location);
      await tester.pumpWidget(
        _Scope(
          auth: authController,
          remote: remote,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('cold-start link opens the card directly, without home', (
      tester,
    ) async {
      final remote = _FakeUserRemote((_) async => _card());
      final router = await open(tester, remote);

      expect(find.text('Describe Quiet Fox in 3 words'), findsOneWidget);
      expect(find.text('Kind'), findsOneWidget);
      expect(remote.requested, [_code]);
      expect(router.state.uri.toString(), '/personality/$_code');
    });

    testWidgets(
      'warm-start link switches card; duplicate delivery is a no-op',
      (tester) async {
        final remote = _FakeUserRemote((code) async => _card(shareCode: code));
        final router = await open(tester, remote);

        router.go('/personality/$_code');
        await tester.pumpAndSettle();
        expect(remote.requested, [_code]);

        router.go('/personality/$_otherCode');
        await tester.pumpAndSettle();
        expect(remote.requested, [_code, _otherCode]);
      },
    );

    testWidgets(
      'signed-out user is sent to onboarding and then back to the card',
      (tester) async {
        final remote = _FakeUserRemote((_) async => _card());
        final auth = _auth(loggedIn: false);
        final router = await open(tester, remote, auth: auth);
        expect(router.state.uri.toString(), startsWith('/onboarding'));
        expect(remote.requested, isEmpty);

        await auth.verifyOtp(phone: '+910000000000', otp: '123456');
        await tester.pumpAndSettle();
        expect(router.state.uri.toString(), '/personality/$_code');
        expect(find.text('Kind'), findsOneWidget);
        await _drain(tester);
      },
    );

    testWidgets(
      'finished onboarding sends a signed-out user to sign-up, then the card',
      (tester) async {
        final remote = _FakeUserRemote((_) async => _card());
        final auth = _auth(loggedIn: false, completedOnboarding: true);
        final router = await open(tester, remote, auth: auth);
        expect(router.state.uri.toString(), startsWith('/sign-up'));
        expect(remote.requested, isEmpty);

        await auth.verifyOtp(phone: '+910000000000', otp: '123456');
        await tester.pumpAndSettle();
        expect(router.state.uri.toString(), '/personality/$_code');
        expect(find.text('Kind'), findsOneWidget);
        await _drain(tester);
      },
    );
  });

  group('SharedPersonalityScreen states', () {
    Future<_FakeUserRemote> pump(
      WidgetTester tester,
      Future<SharedPersonalityCard> Function(String) onGet, {
      String shareCode = _code,
      bool loggedIn = true,
      _FakeUserRemote? remote,
    }) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fake = remote ?? _FakeUserRemote(onGet);
      final auth = _auth(loggedIn: loggedIn);
      await tester.pumpWidget(
        _Scope(
          auth: auth,
          remote: fake,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) =>
                      SharedPersonalityScreen(shareCode: shareCode),
                ),
                GoRoute(
                  path: AppRoutes.main,
                  builder: (_, _) => const Text('IN THE APP'),
                ),
                GoRoute(
                  path: AppRoutes.signUp,
                  builder: (_, _) => const Text('SIGN UP'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    FilledButton submit(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byType(FilledButton));

    Future<void> pick(WidgetTester tester, List<String> names) async {
      for (final name in names) {
        await tester.tap(find.text(name));
        await tester.pump();
      }
    }

    testWidgets('malformed code shows not-found and makes no API call', (
      tester,
    ) async {
      final remote = await pump(
        tester,
        (_) async => _card(),
        shareCode: 'not-a-code',
      );
      expect(find.text('Card not found'), findsOneWidget);
      expect(remote.requested, isEmpty);
    });

    for (final c
        in <(String, Future<SharedPersonalityCard> Function(String), String)>[
          ('404', (_) async => throw _http(404), 'Card not found'),
          ('403', (_) async => throw _http(403), 'Card unavailable'),
          ('500', (_) async => throw _http(500), "Couldn't load this card"),
          (
            'completed card',
            (_) async =>
                _card(status: PersonalityCardStatus.completed, canVote: false),
            'Voting is closed',
          ),
        ]) {
      testWidgets('error state: ${c.$1}', (tester) async {
        await pump(tester, c.$2);
        expect(find.text(c.$3), findsOneWidget);
        if (c.$1 == 'completed card') {
          expect(
            find.text("Quiet Fox's card already has all its votes."),
            findsOneWidget,
          );
          expect(find.text('2 of 5 votes in'), findsOneWidget);
        }
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }

    testWidgets('failed load can be retried', (tester) async {
      var calls = 0;
      await pump(tester, (_) async {
        if (++calls == 1) throw _http(500);
        return _card();
      });
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Kind'), findsOneWidget);
    });

    testWidgets('already voted shows the message, not the traits', (
      tester,
    ) async {
      await pump(tester, (_) async => _card(hasVoted: true, canVote: false));
      expect(find.text('You already voted'), findsOneWidget);
      expect(find.text('Kind'), findsNothing);
    });

    testWidgets('own card cannot be voted on', (tester) async {
      await pump(tester, (_) async => _card(isOwner: true, canVote: false));
      expect(find.text('This is your card'), findsOneWidget);
      expect(find.text('Share again'), findsOneWidget);
      expect(find.text('Kind'), findsNothing);
    });

    testWidgets('submit needs exactly 3 traits and sends them in order', (
      tester,
    ) async {
      final remote = await pump(tester, (_) async => _card());
      expect(submit(tester).onPressed, isNull);

      await pick(tester, ['Loyal', 'Kind']);
      expect(submit(tester).onPressed, isNull);

      await pick(tester, ['Bold']);
      expect(find.text('3 of 3'), findsOneWidget);
      expect(submit(tester).onPressed, isNotNull);

      // A fourth pick is ignored; unpicking frees a slot.
      await pick(tester, ['Funny']);
      expect(find.text('3 of 3'), findsOneWidget);
      await pick(tester, ['Kind']);
      expect(find.text('2 of 3'), findsOneWidget);
      await pick(tester, ['Funny']);

      await tester.tap(find.text('Send my vote'));
      await tester.pumpAndSettle();

      expect(remote.votes, hasLength(1));
      expect(remote.votes.single.$1, _code);
      expect(remote.votes.single.$2, ['t3', 't4', 't2']);
      expect(find.text('IN THE APP'), findsOneWidget);
    });

    testWidgets('logged-out voter is sent to sign-up, no vote is cast', (
      tester,
    ) async {
      final remote = await pump(tester, (_) async => _card(), loggedIn: false);
      expect(find.text('Log in to vote'), findsOneWidget);
      await pick(tester, ['Kind', 'Funny', 'Loyal']);
      await tester.tap(find.text('Log in to vote'));
      await tester.pumpAndSettle();

      expect(remote.votes, isEmpty);
      expect(find.text('SIGN UP'), findsOneWidget);
    });

    testWidgets('a failed vote stays on the card and can be retried', (
      tester,
    ) async {
      final remote = _FakeUserRemote((_) async => _card())
        ..voteError = _http(500);
      await pump(tester, (_) async => _card(), remote: remote);
      await pick(tester, ['Kind', 'Funny', 'Loyal']);

      await tester.tap(find.text('Send my vote'));
      await tester.pumpAndSettle();
      expect(find.text('IN THE APP'), findsNothing);
      expect(find.text('3 of 3'), findsOneWidget);

      remote.voteError = null;
      await tester.tap(find.text('Send my vote'));
      await tester.pumpAndSettle();
      expect(remote.votes.length, 2);
      expect(find.text('IN THE APP'), findsOneWidget);
    });

    for (final c in <(String, DioException, String)>[
      (
        'already voted (409 ALREADY_VOTED)',
        _http(409, code: 'ALREADY_VOTED'),
        'You already voted',
      ),
      ('own card (403)', _http(403, code: 'FORBIDDEN'), 'This is your card'),
      (
        'not collecting (409)',
        _http(409, code: 'CONFLICT'),
        'Voting is closed',
      ),
      ('removed (404)', _http(404, code: 'NOT_FOUND'), 'Card not found'),
    ]) {
      testWidgets('vote rejected by the API: ${c.$1}', (tester) async {
        final remote = _FakeUserRemote((_) async => _card())..voteError = c.$2;
        await pump(tester, (_) async => _card(), remote: remote);
        await pick(tester, ['Kind', 'Funny', 'Loyal']);

        await tester.tap(find.text('Send my vote'));
        await tester.pumpAndSettle();

        expect(find.text(c.$3), findsOneWidget);
        expect(find.text('IN THE APP'), findsNothing);
      });
    }
  });
}

/// The onboarding preview animation schedules a timer; let it fire before the
/// test ends.
Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}
