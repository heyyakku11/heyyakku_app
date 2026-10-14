/// A unit of work for [BackgroundApiWorker].
///
/// Keep [execute] free of UI; feature code owns side effects (storage, alerts).
class BackgroundJob {
  const BackgroundJob({
    required this.id,
    required this.type,
    required this.execute,
    this.maxRetries = 0,
  });

  /// Dedupes pending/in-flight jobs with the same id.
  final String id;

  /// Feature key (e.g. `createGuest`) for result filtering.
  final String type;

  final Future<Object?> Function() execute;

  /// Retries after the first failure. Total attempts = [maxRetries] + 1.
  final int maxRetries;
}

/// Terminal outcome of a [BackgroundJob] (after all retries).
class BackgroundJobResult {
  const BackgroundJobResult({
    required this.id,
    required this.type,
    required this.success,
    required this.attempt,
    this.data,
    this.error,
  });

  final String id;
  final String type;
  final bool success;
  final int attempt;
  final Object? data;
  final Object? error;
}
