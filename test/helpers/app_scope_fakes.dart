import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/auth/login_auth_service.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/device/device_registration_service.dart';
import 'package:yakku/core/payments/payment_flow_controller.dart';
import 'package:yakku/core/payments/pending_payment_store.dart';
import 'package:yakku/core/payments/pending_purchase_intent.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/datasources/payment_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/data/repositories/draft_poll_store.dart';
import 'package:yakku/data/repositories/mock_poll_repository.dart';
import 'package:yakku/data/repositories/personality_card_store.dart';
import 'package:yakku/data/repositories/poll_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';

/// An [AppScope] for widget tests. Everything is a [Fake] that throws when
/// used, except what a test passes in.
Widget testAppScope({
  required AskBackRemoteDataSource askBack,
  required AskBackRealtime realtime,
  required AskBackInboxController inbox,
  required Widget child,
  CheckApiRepository? checkApi,
  UserRemoteDataSource? userRemote,
  PaymentRemoteDataSource? payments,
  PendingPaymentStore? pendingPayments,
  PendingPurchaseStore? pendingPurchase,
  PaymentFlowController? paymentFlow,
  RazorpayCheckoutService? razorpayCheckout,
  PersonalityCardStore? personalityCards,
  AuthController? authController,
}) {
  final resolvedPayments = payments ?? _PaymentsFake();
  final resolvedPendingPayments =
      pendingPayments ??
      PendingPaymentStore(secureStorage: SecureStorageService.inMemory());
  final resolvedCheckout = razorpayCheckout ?? _RazorpayCheckoutFake();
  return AppScope(
    themeController: _ThemeFake(),
    authController: authController ?? _AuthFake(),
    loginAuth: _LoginFake(),
    backgroundApiWorker: _WorkerFake(),
    polls: _PollsFake(),
    pollApi: _PollApiFake(),
    checkApi: checkApi ?? _CheckApiFake(),
    activityPolls: _ActivityFake(),
    userRemote: userRemote ?? _UserFake(),
    payments: resolvedPayments,
    pendingPayments: resolvedPendingPayments,
    pendingPurchase: pendingPurchase ?? _PendingPurchaseFake(),
    paymentFlow:
        paymentFlow ??
        PaymentFlowController(
          payments: resolvedPayments,
          pendingPayments: resolvedPendingPayments,
          checkout: resolvedCheckout,
        ),
    razorpayCheckout: resolvedCheckout,
    notifications: _NotificationsFake(),
    deviceRegistration: _DeviceFake(),
    draftPolls: _DraftsFake(),
    askBack: askBack,
    askBackRealtime: realtime,
    askBackInbox: inbox,
    personalityCards: personalityCards ?? _CardsFake(),
    child: child,
  );
}

class _ThemeFake extends Fake implements ThemeController {}

class _AuthFake extends Fake implements AuthController {}

class _LoginFake extends Fake implements LoginAuthService {}

class _WorkerFake extends Fake implements BackgroundApiWorker {}

class _PollsFake extends Fake implements MockPollRepository {}

class _PollApiFake extends Fake implements PollApiRepository {}

class _CheckApiFake extends Fake implements CheckApiRepository {}

class _ActivityFake extends Fake implements ActivityPollRepository {}

class _UserFake extends Fake implements UserRemoteDataSource {
  @override
  Future<UserProfileResponse> getMe() async {
    return UserProfileResponse(
      profile: const UserProfileDetails(anonymousName: 'Anon'),
      account: const UserAccountDetails(
        status: 'Active',
        phoneNumber: '9999999999',
      ),
      stats: const UserStatsDetails(
        cardsMade: 0,
        votesCast: 0,
        streak: UserStreakSummary(currentStreak: 0, longestStreak: 0),
      ),
    );
  }
}

class _PaymentsFake extends Fake implements PaymentRemoteDataSource {}

class _RazorpayCheckoutFake extends Fake implements RazorpayCheckoutService {
  @override
  bool get isOpening => false;

  @override
  bool get isSessionActive => false;
}

class _PendingPurchaseFake extends Fake implements PendingPurchaseStore {}

class _NotificationsFake extends Fake implements NotificationRemoteDataSource {}

class _DeviceFake extends Fake implements DeviceRegistrationService {}

class _DraftsFake extends Fake implements DraftPollStore {}

class _CardsFake extends Fake implements PersonalityCardStore {
  @override
  Future<void> refresh() async {}
}
