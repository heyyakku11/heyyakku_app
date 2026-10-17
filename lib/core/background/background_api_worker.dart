import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yakku/core/background/background_job.dart';

/// In-memory fire-and-forget API job runner with retries and result events.
///
/// Intentionally knows nothing about auth, Dio, or UI — callers supply
/// [BackgroundJob.execute] and react to [results].
class BackgroundApiWorker {
  BackgroundApiWorker({this._retryDelay = const Duration(milliseconds: 800)});

  final Duration _retryDelay;
  final StreamController<BackgroundJobResult> _resultsController =
      StreamController<BackgroundJobResult>.broadcast();
  final Set<String> _activeIds = <String>{};

  Stream<BackgroundJobResult> get results => _resultsController.stream;

  bool isPending(String id) => _activeIds.contains(id);

  /// Enqueues [job]. Safe to call from UI without awaiting.
  ///
  /// Jobs with an id already pending or in-flight are ignored.
  void enqueue(BackgroundJob job) {
    if (_activeIds.contains(job.id)) return;
    _activeIds.add(job.id);
    unawaited(_run(job));
  }

  Future<void> _run(BackgroundJob job) async {
    final maxAttempts = job.maxRetries + 1;
    Object? lastError;
    Object? data;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        data = await job.execute();
        _emit(
          BackgroundJobResult(
            id: job.id,
            type: job.type,
            success: true,
            attempt: attempt,
            data: data,
          ),
        );
        return;
      } catch (error, stackTrace) {
        lastError = error;
        if (kDebugMode) {
          debugPrint(
            '[BackgroundApiWorker] ${job.type} attempt $attempt/$maxAttempts '
            'failed: $error',
          );
          debugPrint('$stackTrace');
        }
        if (attempt < maxAttempts) {
          await Future<void>.delayed(_retryDelay);
        }
      }
    }

    _emit(
      BackgroundJobResult(
        id: job.id,
        type: job.type,
        success: false,
        attempt: maxAttempts,
        error: lastError,
      ),
    );
  }

  void _emit(BackgroundJobResult result) {
    _activeIds.remove(result.id);
    if (!_resultsController.isClosed) {
      _resultsController.add(result);
    }
  }

  void dispose() {
    unawaited(_resultsController.close());
    _activeIds.clear();
  }
}
