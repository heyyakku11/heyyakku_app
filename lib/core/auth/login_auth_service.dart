import 'dart:async';

import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/background/background_api_worker.dart';
import 'package:yakku/core/background/background_job.dart';
import 'package:yakku/data/models/auth/send_otp_data.dart';

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

  final AuthController _authController;
  final BackgroundApiWorker _worker;
  StreamSubscription<BackgroundJobResult>? _resultsSubscription;
  Completer<SendOtpData>? _sendCompleter;

  /// Completes when the current background send finishes (success or error).
  Future<SendOtpData>? get pendingSend => _sendCompleter?.future;

  bool get isSending =>
      _sendCompleter != null && !(_sendCompleter?.isCompleted ?? true);

  /// Fire-and-forget send OTP. Callers may pop UI immediately and await
  /// [pendingSend] on the next screen.
  void sendOtpInBackground({required String phone, String? name}) {
    if (_worker.isPending(jobId) || isSending) return;

    final completer = Completer<SendOtpData>();
    _sendCompleter = completer;

    _worker.enqueue(
      BackgroundJob(
        id: jobId,
        type: jobType,
        maxRetries: 0,
        execute: () => _authController.sendOtp(phone, name: name),
      ),
    );
  }

  void _onWorkerResult(BackgroundJobResult result) {
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
  }
}
