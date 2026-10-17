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
import 'package:yakku/data/datasources/notification_preference_remote_data_source.dart';
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
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/repositories/poll_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';

const _id = '0cbe6985-219f-4ed7-b780-b93fe2be5fe1';
const _otherId = '11111111-2222-3333-4444-555555555555';

PollResponse _poll({
  String id = _id,
  String status = 'active',
  String visibility = 'public',
  DateTime? expiresAt,
}) => PollResponse(
  id: id,
  question: 'Pizza or pasta?',
  contentType: 'question',
  status: status,
  visibility: visibility,
  expiresAt: expiresAt,
  createdAt: DateTime.utc(2026, 1, 1),
  totalVoteCount: 3,
  options: const [
    PollOptionResponse(id: 'o1', text: 'Pizza', sortOrder: 1),
    PollOptionResponse(id: 'o2', text: 'Pasta', sortOrder: 2),
  ],
);

class _FakePollRemote extends Fake implements PollRemoteDataSource {
  _FakePollRemote(this.onGet);

  final Future<PollResponse> Function(String id) onGet;
  final requested = <String>[];

  @override
  Future<PollResponse> getPollById(String pollId) {
    requested.add(pollId);
    return onGet(pollId);
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
      notificationPreferences: _F11(),
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

class _F11 extends Fake implements NotificationPreferenceRemoteDataSource {}

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
  group('PollDeepLink.pollIdFromUrl', () {
    test('accepts the canonical URL and lower-cases the id', () {
      expect(
        PollDeepLink.pollIdFromUrl(
          Uri.parse(
            'https://heyyakku-web.vercel.app/vote/${_id.toUpperCase()}',
          ),
        ),
        _id,
      );
    });

    test('ignores query and fragment', () {
      expect(
        PollDeepLink.pollIdFromUrl(
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
      'https://heyyakku-web.vercel.app/vote/not-a-uuid',
      'https://heyyakku-web.vercel.app/vote/$_id/extra',
      'https://heyyakku-web.vercel.app/',
      'yakku://vote/$_id',
    ]) {
      test('rejects $bad', () {
        expect(PollDeepLink.pollIdFromUrl(Uri.parse(bad)), isNull);
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
        final remote = _FakePollRemote((id) async => _poll(id: id));
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
      h.router.go('/vote/not-a-uuid');
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
      (
        'private',
        (_) async => _poll(visibility: 'private'),
        'Poll unavailable',
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
}

/// The onboarding preview animation schedules a timer; let it fire before the
/// test ends.
Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}
