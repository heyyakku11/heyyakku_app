import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/auth/login_auth_service.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/device/device_registration_service.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/core/theme/theme_controller.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/datasources/notification_remote_data_source.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/data/repositories/draft_poll_store.dart';
import 'package:yakku/data/repositories/media_upload_repository.dart';
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
  PersonalityCardStore? personalityCards,
}) {
  return AppScope(
    themeController: _ThemeFake(),
    authController: _AuthFake(),
    loginAuth: _LoginFake(),
    backgroundApiWorker: _WorkerFake(),
    polls: _PollsFake(),
    pollApi: _PollApiFake(),
    checkApi: checkApi ?? _CheckApiFake(),
    mediaUploads: _MediaFake(),
    activityPolls: _ActivityFake(),
    userRemote: userRemote ?? _UserFake(),
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

class _MediaFake extends Fake implements MediaUploadRepository {}

class _ActivityFake extends Fake implements ActivityPollRepository {}

class _UserFake extends Fake implements UserRemoteDataSource {}

class _NotificationsFake extends Fake implements NotificationRemoteDataSource {}

class _DeviceFake extends Fake implements DeviceRegistrationService {}

class _DraftsFake extends Fake implements DraftPollStore {}

class _CardsFake extends Fake implements PersonalityCardStore {}
