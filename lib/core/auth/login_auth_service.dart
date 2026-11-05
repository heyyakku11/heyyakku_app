import 'dart:async';

import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/background/background_job.dart';
import 'package:yakku/data/models/auth/send_otp_data.dart';
import 'package:yakku/data/models/device/login_device_model.dart';

/// Enqueues login send-OTP work on [BackgroundApiWorker].
///
/// Exposes [pendingSend] so UI can navigate immediately and still observe the
/// in-flight result (avoids missing a broadcast [BackgroundApiWorker.results]
/// event that arrives before the next sheet subscribes).
class LoginAuthService {
  LoginAuthService({
    required AuthController authController,
    required BackgroundApiWorker worker,
  }) : _authController = authController,
       _worker = worker {
    _resultsSubscription = _worker.results.listen(_onWorkerResult);
  }

  static const jobId = 'sendOtp';
  static const jobType = 'sendOtp';
  static const verifyJobId = 'verifyOtp';
  static const verifyJobType = 'verifyOtp';

  final AuthController _authController;
  final BackgroundApiWorker _worker;
  StreamSubscription<BackgroundJobResult>? _resultsSubscription;
  Completer<SendOtpData>? _sendCompleter;
  Completer<void>? _verifyCompleter;

  /// Completes when the current background send finishes (success or error).
  Future<SendOtpData>? get pendingSend => _sendCompleter?.future;

  bool get isSending =>
      _sendCompleter != null && !(_sendCompleter?.isCompleted ?? true);

  /// Fire-and-forget send OTP. Callers may pop UI immediately and await
  /// [pendingSend] on the next screen.
  void sendOtpInBackground({required String phone}) {
    if (_worker.isPending(jobId) || isSending) return;

    final completer = Completer<SendOtpData>();
    // A failure is also delivered to whoever awaits [pendingSend]; this only
    // keeps an unobserved failure from surfacing as an uncaught error.
    completer.future.ignore();
    _sendCompleter = completer;

    _worker.enqueue(
      BackgroundJob(
        id: jobId,
        type: jobType,
        maxRetries: 0,
        execute: () => _authController.sendOtp(phone),
      ),
    );
  }

  /// Completes when the current background verify finishes. Succeeds once
  /// the user is logged in; fails with the API error otherwise.
  Future<void>? get pendingVerify => _verifyCompleter?.future;

  bool get isVerifying =>
      _verifyCompleter != null && !(_verifyCompleter?.isCompleted ?? true);

  /// Verifies the OTP on [BackgroundApiWorker] and returns the in-flight
  /// result. Does nothing new while a verify is already running.
  Future<void> verifyOtpInBackground({
    required String phone,
    required String otp,
    String? guestToken,
    LoginDeviceModel? device,
  }) {
    final running = _verifyCompleter;
    if (running != null && !running.isCompleted) return running.future;

    final completer = Completer<void>();
    completer.future.ignore();
    _verifyCompleter = completer;

    _worker.enqueue(
      BackgroundJob(
        id: verifyJobId,
        type: verifyJobType,
        maxRetries: 0,
        execute: () async {
          await _authController.verifyOtp(
            phone: phone,
            otp: otp,
            guestToken: guestToken,
            device: device,
          );
          return null;
        },
      ),
    );
    return completer.future;
  }

  void _onVerifyResult(BackgroundJobResult result) {
    final completer = _verifyCompleter;
    if (completer == null || completer.isCompleted) return;
    if (result.success) {
      completer.complete();
    } else {
      completer.completeError(
        result.error ?? StateError('Failed to verify OTP. Please try again.'),
      );
    }
  }

  void _onWorkerResult(BackgroundJobResult result) {
    if (result.type == verifyJobType) {
      _onVerifyResult(result);
      return;
    }
    if (result.type != jobType) return;
    final completer = _sendCompleter;
    if (completer == null || completer.isCompleted) return;

    if (result.success) {
      final data = result.data;
      if (data is SendOtpData) {
        completer.complete(data);
      } else {
        completer.completeError(
          StateError('Send OTP succeeded without SendOtpData'),
        );
      }
      return;
    }

    completer.completeError(
      result.error ?? StateError('Failed to send OTP. Please try again.'),
    );
  }

  void dispose() {
    unawaited(_resultsSubscription?.cancel());
    _resultsSubscription = null;
    final completer = _sendCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(StateError('LoginAuthService disposed'));
    }
    _sendCompleter = null;
    final verify = _verifyCompleter;
    if (verify != null && !verify.isCompleted) {
      verify.completeError(StateError('LoginAuthService disposed'));
    }
    _verifyCompleter = null;
  }
}
