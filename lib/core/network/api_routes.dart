abstract final class ApiRoutes {
  // Auth
  static const String sendOtp = '/api/v1/auth/send';
  static const String verifyOtp = '/api/v1/auth/verify';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // Guests
  static const String guests = '/api/v1/guests';

  // Devices
  static const String registerDevice = '/api/v1/devices/register';

  // Checks
  static const String checks = '/api/v1/checks';
  static const String makeCheck = '/api/v1/checks/make';
  static const String myChecks = '/api/v1/checks/mine';

  // Polls
  static const String createPoll = '/api/v1/users/poll/create';
  static const String castVote = '/api/v1/polls/vote';

  static String pollById(String pollId) => '/api/v1/polls/$pollId';

  static String pollByShareCode(String shareCode) =>
      '/api/v1/polls/share/$shareCode';

  // User
  static const String getMe = '/api/v1/users';
  static const String deleteMe = '/api/v1/users/me';
  static const String askedPolls = '/api/v1/users/asked-polls';
  static const String answeredPolls = '/api/v1/users/answered-polls';
  static const String savedPolls = '/api/v1/users/saved-polls';

  static String viewPoll(String pollId) => '/api/v1/users/view-poll/$pollId';

  static String closePoll(String pollId) =>
      '/api/v1/users/close-poll/$pollId/close';

  static String deletePoll(String pollId) =>
      '/api/v1/users/delete-poll/$pollId';

  static String savePoll(String pollId) => '/api/v1/users/save-poll/$pollId';

  // Notification preferences
  static const String notificationPreferences =
      '/api/v1/notification-preferences';

  // Media upload sessions
  static const String mediaUploadSessions = '/api/v1/media-upload-sessions';

  static String mediaUploadSessionById(String sessionId) =>
      '$mediaUploadSessions/$sessionId';

  static String mediaUploadSessionComplete(String sessionId) =>
      '$mediaUploadSessions/$sessionId/complete';

  static String mediaUploadSessionCancel(String sessionId) =>
      '$mediaUploadSessions/$sessionId/cancel';
}
