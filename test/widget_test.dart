import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakku/core/auth/user_preferences.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/models/auth/logout_request.dart';
import 'package:yakku/data/models/auth/send_otp_request_model.dart';
import 'package:yakku/data/models/auth/verify_otp_data.dart';
import 'package:yakku/data/models/auth/verify_otp_request_model.dart';
import 'package:yakku/main.dart';
import 'package:yakku/presentation/dashboard.dart';
import 'package:yakku/presentation/screens/activity_screen.dart';
import 'package:yakku/presentation/screens/create_screen.dart';
import 'package:yakku/presentation/screens/home_screen.dart';
import 'package:yakku/presentation/screens/onboarding_screen.dart';
import 'package:yakku/presentation/screens/profile_screen.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/presentation/widgets/otp_bottom_sheet.dart';
import 'package:yakku/presentation/widgets/poll_card.dart';
import 'fakes/fake_online_internet_connection_service.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<void> sendOtp(SendOtpRequestModel request) async {}

  @override
  Future<VerifyOtpData> verifyOtp(VerifyOtpRequestModel request) async {
    return VerifyOtpData(
      id: 'test-user-id',
      email: request.email,
      displayName: 'yakku@test',
      purpose: 'Registration',
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      accessTokenExpiresInSeconds: 900,
      refreshTokenExpiresInSeconds: 604800,
    );
  }

  @override
  Future<void> logout(
    LogoutRequestModel request, {
    String? accessToken,
  }) async {}
}

Widget _testApp({
  bool isUserLogged = false,
  String? email,
  String? displayName,
  SecureStorageService? secureStorage,
}) {
  return MyApp(
    isUserLogged: isUserLogged,
    email: email,
    displayName: displayName,
    authRemoteDataSource: _FakeAuthRemoteDataSource(),
    secureStorage: secureStorage ?? SecureStorageService.inMemory(),
    internetConnectionService: FakeOnlineInternetConnectionService(),
  );
}

Future<void> _completeLogin(
  WidgetTester tester, {
  SecureStorageService? secureStorage,
}) async {
  await tester.pumpWidget(_testApp(secureStorage: secureStorage));
  await tester.pumpAndSettle();

  expect(find.text('Get Started'), findsOneWidget);
  await tester.enterText(
    find.widgetWithText(TextField, 'Email'),
    'user@example.com',
  );
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();

  final otpFields = find.descendant(
    of: find.byType(OtpBottomSheet),
    matching: find.byType(TextField),
  );
  for (var i = 0; i < 6; i++) {
    await tester.enterText(otpFields.at(i), '${i + 1}');
  }
  await tester.pumpAndSettle();

  await tester.tap(find.text('Verify Email'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'yakku',
      packageName: 'com.example.yakku',
      version: '1.0.3',
      buildNumber: '4',
      buildSignature: '',
    );
  });

  testWidgets('Verify Email stays disabled until all six digits are entered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'user@example.com',
    );
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    ElevatedButton verifyButton() => tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Verify Email'),
    );

    expect(verifyButton().onPressed, isNull);

    final otpFields = find.descendant(
      of: find.byType(OtpBottomSheet),
      matching: find.byType(TextField),
    );

    for (var i = 0; i < 5; i++) {
      await tester.enterText(otpFields.at(i), '${i + 1}');
    }
    await tester.pumpAndSettle();
    expect(verifyButton().onPressed, isNull);

    await tester.enterText(otpFields.at(5), '6');
    await tester.pumpAndSettle();
    expect(verifyButton().onPressed, isNotNull);
  });

  testWidgets('Verify email opens the dashboard home screen', (
    WidgetTester tester,
  ) async {
    final secureStorage = SecureStorageService.inMemory();
    await _completeLogin(tester, secureStorage: secureStorage);

    expect(find.byType(Dashboard), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.byType(CreateScreen), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(UserPreferences.isUserLoggedKey), isTrue);
    expect(prefs.getString(StorageKeys.email), 'user@example.com');
    expect(prefs.getString(StorageKeys.displayName), 'yakku@test');
    expect(await secureStorage.read(StorageKeys.accessToken), 'test-access-token');
    expect(
      await secureStorage.read(StorageKeys.refreshToken),
      'test-refresh-token',
    );
  });

  testWidgets('Logged-in launch opens dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      UserPreferences.isUserLoggedKey: true,
    });

    await tester.pumpWidget(_testApp(isUserLogged: true));
    await tester.pumpAndSettle();

    expect(find.byType(Dashboard), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('Logging out returns to onboarding and clears the flag', (
    WidgetTester tester,
  ) async {
    final secureStorage = SecureStorageService.inMemory();
    await _completeLogin(tester, secureStorage: secureStorage);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(Dashboard), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(UserPreferences.isUserLoggedKey), isFalse);
    expect(prefs.getString(StorageKeys.email), isNull);
    expect(prefs.getString(StorageKeys.displayName), isNull);
    expect(await secureStorage.read(StorageKeys.accessToken), isNull);
    expect(await secureStorage.read(StorageKeys.refreshToken), isNull);
  });

  testWidgets('Dashboard tabs open Home, Create, Activity, and Profile', (
    WidgetTester tester,
  ) async {
    await _completeLogin(tester);

    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateScreen), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityScreen), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('Ask Anything switches to the Create tab', (
    WidgetTester tester,
  ) async {
    await _completeLogin(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(CreateScreen), findsNothing);

    await tester.tap(find.text('Ask Yours'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateScreen), findsOneWidget);
    expect(
      find.widgetWithText(TextField, "What's on your mind?"),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Option 1'), findsNothing);
    expect(find.text('Ask anything. Get real opinions.'), findsOneWidget);

    final nextButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Next'),
    );
    expect(nextButton.onPressed, isNull);
  });

  testWidgets('Home feed renders poll cards and Make it your actions', (
    WidgetTester tester,
  ) async {
    await _completeLogin(tester);

    const questions = [
      'Should I text them again?',
      'Which activities do you enjoy on weekends?',
      'Which design do you like the most?',
      'What should we have for dinner tonight?',
      'Which features should we add to the app?',
      'Which travel destination would you choose?',
    ];

    final scrollable = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(Scrollable),
    );
    for (final question in questions) {
      await tester.scrollUntilVisible(
        find.text(question),
        400,
        scrollable: scrollable,
      );
      expect(find.text(question), findsOneWidget);
      if (question == 'Which features should we add to the app?') {
        expect(find.text('Dark mode'), findsOneWidget);
        expect(find.text('Reminders'), findsOneWidget);
        expect(find.text('Biometric lock'), findsNothing);
        expect(find.text('Something else'), findsWidgets);
      }
      if (question == 'Which activities do you enjoy on weekends?') {
        expect(find.text('Playing games'), findsOneWidget);
        expect(find.text('Reading'), findsNothing);
      }
    }

    expect(find.byType(PollCard), findsAtLeastNWidgets(1));

    await tester.scrollUntilVisible(
      find.text('Should I text them again?'),
      -400,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.text('Make it your').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make it your').first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Share'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(find.text('Share "Should I text them again?"'), findsOneWidget);
  });

  testWidgets('Create poll validates and posts locally', (
    WidgetTester tester,
  ) async {
    await _completeLogin(tester);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Option 1'), findsNothing);
    expect(find.text('Photo'), findsOneWidget);

    ElevatedButton nextButton() => tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Next'),
    );
    expect(nextButton().onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, "What's on your mind?"),
      'Is the prototype working?',
    );
    await tester.pump();
    expect(nextButton().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Option 1'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Option 2'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('Photo'), findsNothing);
    expect(nextButton().onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Option 1'), 'Yes');
    await tester.enterText(find.widgetWithText(TextField, 'Option 2'), 'No');
    await tester.pump();
    expect(nextButton().onPressed, isNotNull);

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.pumpAndSettle();

    expect(
      find.text('Voters can add their own option while voting'),
      findsOneWidget,
    );
    expect(find.text('Choose audience'), findsOneWidget);
    expect(find.text('My Circle'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Ask Yakku'), findsOneWidget);

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Ask Yakku'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Ask Yakku'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateScreen), findsOneWidget);
    expect(find.text('Poll posted anonymously'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Option 1'), findsNothing);
    expect(find.text('Photo'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('Activity tab shows asked polls by default', (
    WidgetTester tester,
  ) async {
    await _completeLogin(tester);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityScreen), findsOneWidget);
    expect(find.text('Asked'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ActivityScreen),
        matching: find.text('Should I text them again?'),
      ),
      findsOneWidget,
    );
    expect(find.text('Make it your'), findsNothing);
  });

  testWidgets('Activity screen switches asked and answered poll lists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ActivityScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Asked'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);
    expect(find.text('Make it your'), findsNothing);

    const createdQuestions = [
      'Should I text them again?',
      'Which outfit should I wear tonight?',
      'Which profile picture should I use?',
      'Should I buy this phone?',
      'Where should I go this weekend?',
    ];
    const answeredQuestions = [
      'Should I accept this job offer?',
      'Where should we go for dinner?',
      'Which vacation destination should we choose?',
      'Should I start going to the gym?',
      'Which movie should we watch tonight?',
    ];

    final scrollable = find.descendant(
      of: find.byType(ActivityScreen),
      matching: find.byType(Scrollable),
    );

    for (final question in createdQuestions) {
      await tester.scrollUntilVisible(
        find.text(question),
        400,
        scrollable: scrollable,
      );
      expect(find.text(question), findsOneWidget);
    }
    expect(find.text(answeredQuestions.first), findsNothing);
    expect(find.byType(PollCard), findsAtLeastNWidgets(1));

    await tester.scrollUntilVisible(
      find.text('Should I text them again?'),
      -400,
      scrollable: scrollable,
    );
    expect(find.text('Text them'), findsOneWidget);
    expect(find.text("Don't text them"), findsOneWidget);
    expect(find.text('Wait for them to text first'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsWidgets);
    expect(find.byIcon(Icons.check_box_outline_blank), findsWidgets);

    await tester.tap(find.text('Answered'));
    await tester.pumpAndSettle();

    for (final question in answeredQuestions) {
      await tester.scrollUntilVisible(
        find.text(question),
        400,
        scrollable: scrollable,
      );
      expect(find.text(question), findsOneWidget);
    }
    expect(find.text(createdQuestions.first), findsNothing);
    expect(find.text('Make it your'), findsNothing);
    expect(find.byType(PollCard), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Asked'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Where should I go this weekend?'),
      400,
      scrollable: scrollable,
    );
    expect(find.text('Something else'), findsWidgets);
    expect(find.text('Your friends can add their own answer'), findsWidgets);
    expect(find.text('Chinese'), findsNothing);
    expect(find.text('Romance'), findsNothing);
  });

  testWidgets('Activity screen shows empty states when there are no polls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ActivityScreen(repository: _EmptyActivityPollRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No polls asked yet'), findsOneWidget);
    expect(find.text('No polls answered yet'), findsNothing);
    expect(find.byType(PollCard), findsNothing);

    await tester.tap(find.text('Answered'));
    await tester.pumpAndSettle();

    expect(find.text('No polls asked yet'), findsNothing);
    expect(find.text('No polls answered yet'), findsOneWidget);
    expect(find.byType(PollCard), findsNothing);
  });

  testWidgets('Activity screen shows an error when the repository fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ActivityScreen(repository: _ThrowingActivityPollRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load activity.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(PollCard), findsNothing);
  });

  testWidgets('Dashboard swipe moves between tabs and clamps at the ends', (
    WidgetTester tester,
  ) async {
    await _completeLogin(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(CreateScreen), findsNothing);

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(CreateScreen), findsNothing);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(CreateScreen), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}

class _EmptyActivityPollRepository implements ActivityPollRepository {
  const _EmptyActivityPollRepository();

  @override
  Future<List<PollModel>> getCreatedPolls() async => const [];

  @override
  Future<List<PollModel>> getAnsweredPolls() async => const [];
}

class _ThrowingActivityPollRepository implements ActivityPollRepository {
  const _ThrowingActivityPollRepository();

  @override
  Future<List<PollModel>> getCreatedPolls() async {
    throw Exception('network');
  }

  @override
  Future<List<PollModel>> getAnsweredPolls() async {
    throw Exception('network');
  }
}
