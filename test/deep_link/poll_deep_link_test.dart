import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/auth/auth_token_store.dart';
import 'package:yakku/core/auth/user_preferences.dart';
import 'package:yakku/core/auth/guest_session_service.dart';
import 'package:yakku/core/auth/guest_token_store.dart';
import 'package:yakku/core/auth/login_auth_service.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/device/device_registration_service.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/datasources/guest_remote_data_source.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/datasources/check_remote_data_source.dart';
import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/data/repositories/draft_poll_store.dart';
import 'package:yakku/data/repositories/media_upload_repository.dart';
import 'package:yakku/data/repositories/mock_poll_repository.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';
import 'package:yakku/core/router/app_router.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/datasources/poll_remote_data_source.dart';
import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/shared_content_response.dart';
import 'package:yakku/presentation/widgets/mobile_login_bottom_sheet.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/presentation/screens/answer_poll_screen.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/repositories/poll_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';

const _id = 'aB3dE5gH7k';
const _otherId = 'Zq9xW2mN4p';

PollResponse _poll({
  String id = _id,
  String shareCode = _id,
  String status = 'active',
  String visibility = 'public',
  DateTime? expiresAt,
  VotingStateResponse? voting,
  bool isOwner = false,
}) => PollResponse(
  id: id,
  shareCode: shareCode,
  question: 'Pizza or pasta?',
  contentType: 'question',
  status: status,
  visibility: visibility,
  expiresAt: expiresAt,
  createdAt: DateTime.utc(2026, 1, 1),
  totalVoteCount: 3,
  voting: voting,
  isOwner: isOwner,
  options: const [
    PollOptionResponse(id: 'o1', text: 'Pizza', sortOrder: 1),
    PollOptionResponse(id: 'o2', text: 'Pasta', sortOrder: 2),
  ],
);

class _FakePollRemote extends Fake implements PollRemoteDataSource {
  _FakePollRemote(this.onGet);

  final Future<PollResponse> Function(String id) onGet;
  final requested = <String>[];
  final votes = <CastVoteRequest>[];
  Object? castError;

  @override
  Future<CastVoteResponse> castVote(CastVoteRequest request) async {
    votes.add(request);
    final error = castError;
    if (error != null) throw error;
    return CastVoteResponse(
      id: 'v1',
      pollId: 'p1',
      pollOptionId: request.optionId ?? '',
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Future<PollResponse> getPollByShareCode(String shareCode) {
    requested.add(shareCode);
    return onGet(shareCode);
  }
}

class _FakePrefs extends Fake implements UserPreferences {
  @override
  Future<void> setHasEnteredAsGuest(bool value) async {}
}

class _FakeTokens extends Fake implements AuthTokenStore {}

class _FakeAuthRemote extends Fake implements AuthRemoteDataSource {}

DioException _http(int status) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
  ),
);

class _Harness {
  _Harness({bool loggedIn = false, bool guest = false, required this.remote}) {
    auth = AuthController(
      userPreferences: _FakePrefs(),
      tokenStore: _FakeTokens(),
      authRemote: _FakeAuthRemote(),
      isUserLogged: loggedIn,
      hasEnteredAsGuest: guest,
    );
    router = AppRouter.create(auth, navigatorKey: GlobalKey<NavigatorState>());
  }

  final _FakePollRemote remote;
  late final AuthController auth;
  late final GoRouter router;

  Widget build() => _Scope(
    auth: auth,
    pollApi: PollApiRepository(remote),
    child: MaterialApp.router(routerConfig: router),
  );

  String get location => router.state.uri.toString();
}

class _Scope extends StatelessWidget {
  const _Scope({
    required this.auth,
    required this.pollApi,
    required this.child,
  });

  final AuthController auth;
  final PollApiRepository pollApi;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      themeController: _F1(),
      authController: auth,
      guestRemote: _F2(),
      guestTokenStore: _F3(),
      guestSession: _F4(),
      loginAuth: _F5(),
      backgroundApiWorker: _F6(),
      polls: _F7(),
      pollApi: pollApi,
      checkApi: _F14(),
      mediaUploads: _F8(),
      activityPolls: _F9(),
      userRemote: _F10(),
      notifications: _F15(),
      deviceRegistration: _F12(),
      draftPolls: _F13(),
      child: child,
    );
  }
}

class _F1 extends Fake implements ThemeController {}

class _F2 extends Fake implements GuestRemoteDataSource {}

class _F3 extends Fake implements GuestTokenStore {}

class _F4 extends Fake implements GuestSessionService {}

class _F5 extends Fake implements LoginAuthService {}

class _F6 extends Fake implements BackgroundApiWorker {}

class _F7 extends Fake implements MockPollRepository {}

class _F8 extends Fake implements MediaUploadRepository {}

class _F9 extends Fake implements ActivityPollRepository {}

class _F10 extends Fake implements UserRemoteDataSource {}

class _F15 extends Fake implements NotificationRemoteDataSource {}

class _F12 extends Fake implements DeviceRegistrationService {}

class _F13 extends Fake implements DraftPollStore {}

class _F14 extends CheckApiRepository {
  _F14() : super(_FakeCheckRemote());
}

class _FakeCheckRemote extends Fake implements CheckRemoteDataSource {
  @override
  Future<List<CheckResponse>> getChecks() async => const [];
}

void main() {
  group('PollDeepLink.shareCodeFromUrl', () {
    test('accepts the canonical URL and keeps the case of the code', () {
      expect(
        PollDeepLink.shareCodeFromUrl(
          Uri.parse('https://heyyakku-web.vercel.app/vote/$_id'),
        ),
        _id,
      );
    });

    test('ignores query and fragment', () {
      expect(
        PollDeepLink.shareCodeFromUrl(
          Uri.parse('https://heyyakku-web.vercel.app/vote/$_id?admin=1#x'),
        ),
        _id,
      );
    });

    for (final bad in [
      'http://heyyakku-web.vercel.app/vote/$_id',
      'https://evil.example.com/vote/$_id',
      'https://heyyakku-web.vercel.app.evil.com/vote/$_id',
      'https://heyyakku-web.vercel.app/poll/$_id',
      'https://heyyakku-web.vercel.app/vote/',
      'https://heyyakku-web.vercel.app/vote/not-a-code',
      'https://heyyakku-web.vercel.app/vote/$_id/extra',
      'https://heyyakku-web.vercel.app/',
      'yakku://vote/$_id',
    ]) {
      test('rejects $bad', () {
        expect(PollDeepLink.shareCodeFromUrl(Uri.parse(bad)), isNull);
      });
    }
  });

  group('PollDeepLink.safeReturnPath', () {
    test('keeps in-app vote paths only', () {
      expect(PollDeepLink.safeReturnPath('/vote/$_id'), '/vote/$_id');
      expect(PollDeepLink.safeReturnPath('/main'), isNull);
      expect(PollDeepLink.safeReturnPath('https://evil.com/vote/$_id'), isNull);
      expect(PollDeepLink.safeReturnPath('//evil.com/vote/$_id'), isNull);
      expect(PollDeepLink.safeReturnPath(null), isNull);
    });
  });

  group('router + SharedPollScreen', () {
    testWidgets('cold-start link opens the poll directly, without home', (
      tester,
    ) async {
      final remote = _FakePollRemote((_) async => _poll());
      final h = _Harness(loggedIn: true, remote: remote);
      h.router.go('/vote/$_id');
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();

      expect(find.text('Pizza'), findsOneWidget);
      expect(remote.requested, [_id]);
      expect(h.location, '/vote/$_id');
    });

    testWidgets(
      'warm-start link switches poll; duplicate delivery is a no-op',
      (tester) async {
        final remote = _FakePollRemote((id) async => _poll(shareCode: id));
        final h = _Harness(loggedIn: true, remote: remote);
        h.router.go('/vote/$_id');
        await tester.pumpWidget(h.build());
        await tester.pumpAndSettle();

        h.router.go('/vote/$_id');
        await tester.pumpAndSettle();
        expect(remote.requested, [_id]);

        h.router.go('/vote/$_otherId');
        await tester.pumpAndSettle();
        expect(remote.requested, [_id, _otherId]);
      },
    );

    testWidgets('signed-out user is sent to onboarding and then back to poll', (
      tester,
    ) async {
      final remote = _FakePollRemote((_) async => _poll());
      final h = _Harness(remote: remote);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      h.router.go('/vote/$_id');
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();
      expect(h.location, startsWith('/onboarding'));
      expect(remote.requested, isEmpty);

      await h.auth.enterAsGuest();
      await tester.pumpAndSettle();
      expect(h.location, '/vote/$_id');
      expect(find.text('Pizza'), findsOneWidget);
      await _drain(tester);
    });

    testWidgets('onboarding ignores an unsafe return destination', (
      tester,
    ) async {
      final remote = _FakePollRemote((_) async => _poll());
      final h = _Harness(remote: remote);
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      h.router.go('/onboarding?from=https%3A%2F%2Fevil.com');
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();
      await h.auth.enterAsGuest();
      await tester.pumpAndSettle();
      expect(h.location, '/main');
      await _drain(tester);
    });

    testWidgets('malformed id shows not-found, makes no API call', (
      tester,
    ) async {
      final remote = _FakePollRemote((_) async => _poll());
      final h = _Harness(loggedIn: true, remote: remote);
      h.router.go('/vote/not-a-code');
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();
      expect(find.text('Poll not found'), findsOneWidget);
      expect(remote.requested, isEmpty);
    });

    for (final c in <(String, Future<PollResponse> Function(String), String)>[
      ('404', (_) async => throw _http(404), 'Poll not found'),
      ('403', (_) async => throw _http(403), 'Poll unavailable'),
      ('500', (_) async => throw _http(500), "Couldn't load this poll"),
      ('closed', (_) async => _poll(status: 'closed'), 'Poll closed'),
      ('expired', (_) async => _poll(status: 'expired'), 'Poll expired'),
      (
        'past expiresAt',
        (_) async => _poll(expiresAt: DateTime.utc(2020)),
        'Poll expired',
      ),
    ]) {
      testWidgets('error state: ${c.$1}', (tester) async {
        final h = _Harness(loggedIn: true, remote: _FakePollRemote(c.$2));
        h.router.go('/vote/$_id');
        await tester.pumpWidget(h.build());
        await tester.pumpAndSettle();
        expect(find.text(c.$3), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }

    testWidgets('failed load can be retried', (tester) async {
      var calls = 0;
      final remote = _FakePollRemote((_) async {
        if (++calls == 1) throw _http(500);
        return _poll();
      });
      final h = _Harness(loggedIn: true, remote: remote);
      h.router.go('/vote/$_id');
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Pizza'), findsOneWidget);
    });
  });

  group('AnswerPollScreen (vote from a shared link)', () {
    Widget app(_FakePollRemote remote, {bool loggedIn = true}) => _Scope(
      auth: _Harness(loggedIn: loggedIn, remote: remote).auth,
      pollApi: PollApiRepository(remote),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => AnswerPollScreen(poll: _poll()),
            ),
            GoRoute(
              path: AppRoutes.main,
              builder: (_, _) => const Text('IN THE APP'),
            ),
          ],
        ),
      ),
    );

    Future<void> pump(WidgetTester tester, Widget w) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(w);
      await tester.pumpAndSettle();
    }

    ElevatedButton submit(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    testWidgets('shows the card: question, lettered answers, write-your-own', (
      tester,
    ) async {
      await pump(tester, app(_FakePollRemote((_) async => _poll())));

      expect(
        find.textContaining('asked you', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Send vote'), findsOneWidget);
      expect(find.text('Pizza or pasta?'), findsOneWidget);
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Write your own answer'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(submit(tester).onPressed, isNull);
    });

    testWidgets('picking an option shows Why? and casts option + reason', (
      tester,
    ) async {
      final remote = _FakePollRemote((_) async => _poll());
      await pump(tester, app(remote));

      await tester.tap(find.text('Pasta'));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  Carbs!  ');
      await tester.tap(find.text('Send vote'));
      await tester.pumpAndSettle();

      final vote = remote.votes.single;
      expect(vote.shareCode, _id);
      expect(vote.optionId, 'o2');
      expect(vote.customAnswer, isNull);
      expect(vote.reason, 'Carbs!');
      expect(find.text('IN THE APP'), findsOneWidget);
      expect(find.text('Share your poll'), findsNothing);
    });

    testWidgets('reason is optional', (tester) async {
      final remote = _FakePollRemote((_) async => _poll());
      await pump(tester, app(remote));

      await tester.tap(find.text('Pizza'));
      await tester.pump();
      await tester.tap(find.text('Send vote'));
      await tester.pumpAndSettle();

      expect(remote.votes.single.optionId, 'o1');
      expect(remote.votes.single.reason, isNull);
    });

    testWidgets('Something else needs text, then casts a custom answer', (
      tester,
    ) async {
      final remote = _FakePollRemote((_) async => _poll());
      await pump(tester, app(remote));

      await tester.tap(find.text('Write your own answer'));
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(submit(tester).onPressed, isNull, reason: 'no answer typed yet');

      await tester.enterText(find.byType(TextField).first, 'Burgers');
      await tester.enterText(find.byType(TextField).last, 'Always');
      await tester.pump();
      expect(submit(tester).onPressed, isNotNull);
      await tester.tap(find.text('Send vote'));
      await tester.pumpAndSettle();

      final vote = remote.votes.single;
      expect(vote.optionId, isNull);
      expect(vote.customAnswer, 'Burgers');
      expect(vote.reason, 'Always');
    });

    testWidgets('answer and reason lengths are capped', (tester) async {
      await pump(tester, app(_FakePollRemote((_) async => _poll())));

      await tester.tap(find.text('Write your own answer'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'a' * 100);
      await tester.enterText(find.byType(TextField).last, 'b' * 500);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        hasLength(40),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        hasLength(150),
      );
    });

    testWidgets('logged-out voter is asked to log in, no vote is cast', (
      tester,
    ) async {
      final remote = _FakePollRemote((_) async => _poll());
      await pump(tester, app(remote, loggedIn: false));

      expect(find.text('Log in to vote'), findsOneWidget);
      await tester.tap(find.text('Log in to vote'));
      await tester.pumpAndSettle();

      expect(find.byType(MobileLoginBottomSheet), findsOneWidget);
      expect(remote.votes, isEmpty);
    });

    testWidgets('a failed vote stays on the card and can be retried', (
      tester,
    ) async {
      final remote = _FakePollRemote((_) async => _poll())
        ..castError = _http(500);
      await pump(tester, app(remote));

      await tester.tap(find.text('Pizza'));
      await tester.pump();
      await tester.tap(find.text('Send vote'));
      await tester.pumpAndSettle();

      expect(find.text('IN THE APP'), findsNothing);
      expect(find.text('Pizza or pasta?'), findsOneWidget);

      remote.castError = null;
      await tester.tap(find.text('Send vote'));
      await tester.pumpAndSettle();
      expect(remote.votes.length, 2);
      expect(find.text('IN THE APP'), findsOneWidget);
    });
  });

  group('SharedPollScreen voting state from the API', () {
    Future<void> open(
      WidgetTester tester,
      PollResponse poll, {
      required bool loggedIn,
    }) async {
      final h = _Harness(
        loggedIn: loggedIn,
        guest: !loggedIn,
        remote: _FakePollRemote((_) async => poll),
      );
      h.router.go('/vote/$_id');
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();
    }

    testWidgets('already voted (signed in) shows the message, not the card', (
      tester,
    ) async {
      await open(
        tester,
        _poll(voting: const VotingStateResponse(hasVoted: true)),
        loggedIn: true,
      );
      expect(find.text('You already voted'), findsOneWidget);
      expect(find.text('Pizza'), findsNothing);
    });

    testWidgets('own card (signed in) cannot be voted on', (tester) async {
      await open(
        tester,
        _poll(voting: const VotingStateResponse(canVote: true), isOwner: true),
        loggedIn: true,
      );
      expect(find.text('This is your card'), findsOneWidget);
    });

    testWidgets('API says canVote=false (signed in): blocked message', (
      tester,
    ) async {
      await open(
        tester,
        _poll(voting: const VotingStateResponse(blockedReason: 'X')),
        loggedIn: true,
      );
      expect(find.text("You can't vote on this card"), findsOneWidget);
    });

    testWidgets('canVote=true (signed in) shows the card to vote on', (
      tester,
    ) async {
      await open(
        tester,
        _poll(voting: const VotingStateResponse(canVote: true)),
        loggedIn: true,
      );
      expect(find.text('Write your own answer'), findsOneWidget);
      expect(find.text('Send vote'), findsOneWidget);
    });

    testWidgets('guest sees the card with a login prompt', (tester) async {
      await open(
        tester,
        _poll(voting: const VotingStateResponse()),
        loggedIn: false,
      );
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Log in to vote'), findsOneWidget);
    });
  });
}

/// The onboarding preview animation schedules a timer; let it fire before the
/// test ends.
Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}
