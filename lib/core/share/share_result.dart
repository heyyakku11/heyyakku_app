/// Outcome of a share action. Success means the *local* operation completed
/// (link copied, share destination opened) — never that a message was sent.
sealed class ShareResult {
  const ShareResult();
}

final class ShareSuccess extends ShareResult {
  const ShareSuccess({this.feedbackMessage});

  /// Optional confirmation to show the user (e.g. "Link copied").
  final String? feedbackMessage;
}

final class ShareCancelled extends ShareResult {
  const ShareCancelled();
}

final class ShareUnsupported extends ShareResult {
  const ShareUnsupported([this.userMessage = 'Sharing is not available here.']);

  final String userMessage;
}

enum ShareFailureReason {
  invalidPayload,
  launchFailed,
  clipboardFailed,
  unknown,
}

final class ShareFailure extends ShareResult {
  const ShareFailure(this.reason, {required this.userMessage});

  final ShareFailureReason reason;

  /// Concise, user-safe text. Raw exceptions are logged, never shown.
  final String userMessage;
}
