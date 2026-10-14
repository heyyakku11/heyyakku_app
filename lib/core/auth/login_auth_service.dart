import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/background/background_job.dart';

/// Enqueues login send-OTP work on [BackgroundApiWorker].
class LoginAuthService {
  LoginAuthService({
    required this._authController,
    required this._worker,
  });

  static const jobId = 'sendOtp';
  static const jobType = 'sendOtp';

  final AuthController _authController;
  final BackgroundApiWorker _worker;

  /// Fire-and-forget send OTP. Listen to [BackgroundApiWorker.results] for outcome.
  void sendOtpInBackground({required String phone, String? name}) {
    _worker.enqueue(
      BackgroundJob(
        id: jobId,
        type: jobType,
        maxRetries: 0,
        execute: () => _authController.sendOtp(phone, name: name),
      ),
    );
  }
}
