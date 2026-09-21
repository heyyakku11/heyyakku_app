import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakku/core/auth/user_preferences.dart';
import 'package:yakku/core/device/device_registration_service.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/datasources/poll_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/auth/logout_request.dart';
import 'package:yakku/data/models/auth/refresh_token_request.dart';
import 'package:yakku/data/models/auth/send_otp_data.dart';
import 'package:yakku/data/models/auth/send_otp_request_model.dart';
import 'package:yakku/data/models/auth/token_response.dart';
import 'package:yakku/data/models/auth/verify_otp_data.dart';
import 'package:yakku/data/models/auth/verify_otp_request_model.dart';
import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/create_poll_request.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/notification/notification_response.dart';
import 'package:yakku/data/models/user/user_poll_detail_response.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/data/repositories/poll_api_repository.dart';
import 'package:yakku/main.dart';
import 'package:yakku/presentation/dashboard.dart';
import 'package:yakku/presentation/screens/activity_screen.dart';
import 'package:yakku/presentation/screens/answer_poll_screen.dart';
import 'package:yakku/presentation/screens/create_screen.dart';
import 'package:yakku/presentation/screens/home_screen.dart';
import 'package:yakku/presentation/screens/notification_screen.dart';
import 'package:yakku/presentation/screens/onboarding_screen.dart';
import 'package:yakku/presentation/screens/profile_screen.dart';
import 'package:yakku/presentation/screens/view_poll_screen.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll_option.dart';
import 'package:yakku/domain/enums/poll_answer_type.dart';
import 'package:yakku/domain/enums/poll_options_type.dart';
import 'package:yakku/domain/enums/poll_status.dart';
import 'package:yakku/presentation/widgets/otp_bottom_sheet.dart';
import 'package:yakku/presentation/widgets/poll_card.dart';
import 'fakes/fake_online_internet_connection_service.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<SendOtpData> sendOtp(SendOtpRequestModel request) async {
    return const SendOtpData(purpose: 'Registration', expiresInSeconds: 300);
  }

  @override
  Future<VerifyOtpData> verifyOtp(VerifyOtpRequestModel request) async {
    return const VerifyOtpData(
      displayName: 'yakku@test',
      purpose: 'Registration',
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      accessTokenExpiresInSeconds: 900,
      refreshTokenExpiresInSeconds: 604800,
    );
  }

  @override
  Future<TokenResponse> refresh(RefreshTokenRequest request) async {
    return const TokenResponse(
      accessToken: 'refreshed-access-token',
      refreshToken: 'refreshed-refresh-token',
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

class _FakeUserRemoteDataSource implements UserRemoteDataSource {
  @override
  Future<UserProfileResponse> getMe() async {
    return UserProfileResponse(
      id: 'user-1',
      status: 'active',
      email: 'user@example.com',
      displayName: 'yakku@test',
    );
  }

  @override
  Future<UserPollDetailResponse> getOwnedPollDetails(String pollId) async {
    return UserPollDetailResponse(
      pollId: pollId,
      question: 'Asked poll question',
      status: 'active',
      shareToken: 'share-token',
      optionType: 'text',
      createdAt: DateTime.utc(2026, 1, 1),
      totalVoteCount: 12,
      pollOptions: const [
        UserPollDetailOptionResponse(
          id: 'asked_opt_1',
          text: 'Yes',
          sortOrder: 1,
          voteCount: 8,
          percentage: 67,
        ),
        UserPollDetailOptionResponse(
          id: 'asked_opt_2',
          text: 'No',
          sortOrder: 2,
          voteCount: 4,
          percentage: 33,
        ),
      ],
      youVsCrowd: const YouVsCrowdResponse(
        yourOptionId: 'asked_opt_1',
        yourOptionText: 'Yes',
        yourOptionPercentage: 67,
        crowdLeadingOptionId: 'asked_opt_1',
        crowdLeadingOptionText: 'Yes',
        crowdLeadingPercentage: 67,
        agreesWithCrowd: true,
      ),
    );
  }

  @override
  Future<PollResponse> closePoll(String pollId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePoll(String pollId) async {}
}

class _FakePollRemoteDataSource implements PollRemoteDataSource {
  @override
  Future<PollResponse> createPoll(CreatePollRequest request) async {
    final options = request.options;
    return PollResponse(
      id: 'poll-1',
      question: request.question,
      shareToken: 'share-token',
      optionType: request.optionType,
      totalVoteCount: 1,
      selectedOptionId: options.isEmpty ? null : 'option-0',
      options: [
        for (var i = 0; i < options.length; i++)
          PollOptionResponse(
            id: 'option-$i',
            text: options[i].text,
            sortOrder: i,
            voteCount: i == request.selectedOptionIndex ? 1 : 0,
            percentage: i == request.selectedOptionIndex ? 100 : 0,
          ),
      ],
    );
  }

  @override
  Future<CastVoteResponse> castVote({
    required String pollId,
    required CastVoteRequest request,
  }) async {
    return CastVoteResponse(
      id: 'vote-1',
      pollId: pollId,
      pollOptionId: request.optionId,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }
}

Widget _testApp({
  bool isUserLogged = false,
  String? email,
  String? displayName,
  SecureStorageService? secureStorage,
  PollApiRepository? pollApiRepository,
  ActivityPollRepository? activityPollRepository,
  UserRemoteDataSource? userRemoteDataSource,
  NotificationRemoteDataSource? notificationRemoteDataSource,
}) {
  return MyApp(
    isUserLogged: isUserLogged,
    email: email,
    displayName: displayName,
    authRemoteDataSource: _FakeAuthRemoteDataSource(),
    pollApiRepository:
        pollApiRepository ?? PollApiRepository(_FakePollRemoteDataSource()),
    activityPollRepository:
        activityPollRepository ?? const _EmptyActivityPollRepository(),
    userRemoteDataSource: userRemoteDataSource ?? _FakeUserRemoteDataSource(),
    notificationRemoteDataSource:
        notificationRemoteDataSource ??
        const _FakeNotificationRemoteDataSource(),
    secureStorage: secureStorage ?? SecureStorageService.inMemory(),
    internetConnectionService: FakeOnlineInternetConnectionService(),
    deviceRegistrationService: NoOpDeviceRegistrationService(),
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
    expect(
      await secureStorage.read(StorageKeys.accessToken),
      'test-access-token',
    );
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
    expect(find.text('Photo'), findsNothing);
    expect(find.text('Create poll'), findsOneWidget);

    ElevatedButton createButton() => tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Create poll'),
    );
    expect(createButton().onPressed, isNull);
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

  testWidgets('Create poll validates and opens a shareable poll card', (
    WidgetTester tester,
  ) async {
    await _completeLogin(tester);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateScreen), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Option 1'), findsNothing);
    expect(find.text('Photo'), findsNothing);

    ElevatedButton createButton() => tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Create poll'),
    );
    expect(createButton().onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, "What's on your mind?"),
      'Is the prototype working?',
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Option 1'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Option 2'), findsOneWidget);
    expect(createButton().onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Option 1'), 'Yes');
    await tester.enterText(find.widgetWithText(TextField, 'Option 2'), 'No');
    await tester.pumpAndSettle();

    expect(find.text('Add another option'), findsOneWidget);
    expect(
      find.text('Voters can add their own option while voting'),
      findsOneWidget,
    );
    expect(find.text('Option A'), findsOneWidget);
    expect(find.text('Option B'), findsOneWidget);
    expect(createButton().onPressed, isNull);

    await tester.ensureVisible(find.text('Option A'));
    await tester.tap(find.text('Option A'));
    await tester.pumpAndSettle();
    expect(createButton().onPressed, isNotNull);

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Create poll'),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create poll'));
    await tester.pumpAndSettle();

    expect(find.byType(AnswerPollScreen), findsNothing);
    expect(find.text('Your poll is live'), findsOneWidget);
    expect(find.text('Is the prototype working?'), findsWidgets);
    expect(find.text('Yes'), findsWidgets);
    expect(find.text('No'), findsWidgets);
    expect(find.text('Something else'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Share'));
    await tester.pumpAndSettle();

    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('Snapchat'), findsOneWidget);
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
    expect(find.text('No polls asked yet'), findsOneWidget);
    expect(find.text('Make it your'), findsNothing);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('Activity screen switches asked and answered poll lists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ActivityScreen(repository: _SampleActivityPollRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asked'), findsOneWidget);
    expect(find.text('Answered'), findsOneWidget);
    expect(find.text('Asked poll question'), findsOneWidget);
    expect(find.text('Answered poll question'), findsNothing);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(find.text('12 votes'), findsOneWidget);
    expect(find.text('Make it your'), findsNothing);
    expect(find.byType(PollCard), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.tap(find.text('Answered'));
    await tester.pumpAndSettle();

    expect(find.text('Answered poll question'), findsOneWidget);
    expect(find.text('Asked poll question'), findsNothing);
    expect(find.text('Option A'), findsOneWidget);
    expect(find.text('Option B'), findsOneWidget);
    expect(find.text('3 votes'), findsOneWidget);
    expect(find.text('Make it your'), findsNothing);
    expect(find.byType(PollCard), findsOneWidget);

    await tester.tap(find.text('Asked'));
    await tester.pumpAndSettle();

    expect(find.text('Asked poll question'), findsOneWidget);
    expect(find.text('Answered poll question'), findsNothing);
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
    expect(find.byType(RefreshIndicator), findsOneWidget);

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

  testWidgets('Activity poll tap opens view poll with you vs crowd', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        isUserLogged: true,
        activityPollRepository: const _SampleActivityPollRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asked poll question'));
    await tester.pumpAndSettle();

    expect(find.byType(ViewPollScreen), findsOneWidget);
    expect(find.text('You vs crowd'), findsOneWidget);
    expect(find.text('You agree with the crowd'), findsOneWidget);
    expect(find.text('12 votes'), findsWidgets);
    expect(find.text('Your pick'), findsOneWidget);
  });

  testWidgets('Notification screen shows empty state when there are none', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationScreen(
          dataSource: _FakeNotificationRemoteDataSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('Notification screen shows loaded notifications', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationScreen(
          dataSource: _SampleNotificationRemoteDataSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Someone voted on your poll'), findsOneWidget);
    expect(find.text('A friend answered your question.'), findsOneWidget);
    expect(find.text('No notifications yet'), findsNothing);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('Notification screen shows an error when loading fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationScreen(
          dataSource: _ThrowingNotificationRemoteDataSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load notifications.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('No notifications yet'), findsNothing);
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

class _SampleActivityPollRepository implements ActivityPollRepository {
  const _SampleActivityPollRepository();

  static const _asked = PollModel(
    id: 'asked_1',
    question: 'Asked poll question',
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: false,
    status: PollStatus.active,
    totalVoteCount: 12,
    options: [
      PollOptionModel(
        id: 'asked_opt_1',
        type: PollOptionType.text,
        text: 'Yes',
        sortOrder: 1,
        isCustom: false,
      ),
      PollOptionModel(
        id: 'asked_opt_2',
        type: PollOptionType.text,
        text: 'No',
        sortOrder: 2,
        isCustom: false,
      ),
    ],
  );

  static const _answered = PollModel(
    id: 'answered_1',
    question: 'Answered poll question',
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: false,
    status: PollStatus.active,
    totalVoteCount: 3,
    options: [
      PollOptionModel(
        id: 'answered_opt_1',
        type: PollOptionType.text,
        text: 'Option A',
        sortOrder: 1,
        isCustom: false,
      ),
      PollOptionModel(
        id: 'answered_opt_2',
        type: PollOptionType.text,
        text: 'Option B',
        sortOrder: 2,
        isCustom: false,
      ),
    ],
  );

  @override
  Future<List<PollModel>> getCreatedPolls() async => const [_asked];

  @override
  Future<List<PollModel>> getAnsweredPolls() async => const [_answered];
}

class _FakeNotificationRemoteDataSource
    implements NotificationRemoteDataSource {
  const _FakeNotificationRemoteDataSource();

  @override
  Future<NotificationsPage> getMine({String? cursor}) async {
    return const NotificationsPage(items: []);
  }

  @override
  Future<NotificationResponse> markAsRead(String id) {
    throw UnimplementedError();
  }
}

class _SampleNotificationRemoteDataSource
    implements NotificationRemoteDataSource {
  const _SampleNotificationRemoteDataSource();

  @override
  Future<NotificationsPage> getMine({String? cursor}) async {
    return NotificationsPage(
      items: [
        NotificationResponse(
          id: 'n1',
          type: 'poll',
          eventType: 'vote',
          title: 'Someone voted on your poll',
          body: 'A friend answered your question.',
          isRead: false,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );
  }

  @override
  Future<NotificationResponse> markAsRead(String id) {
    throw UnimplementedError();
  }
}

class _ThrowingNotificationRemoteDataSource
    implements NotificationRemoteDataSource {
  const _ThrowingNotificationRemoteDataSource();

  @override
  Future<NotificationsPage> getMine({String? cursor}) {
    throw Exception('network');
  }

  @override
  Future<NotificationResponse> markAsRead(String id) {
    throw UnimplementedError();
  }
}
