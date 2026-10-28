abstract final class ApiRoutes {
  // Auth
  static const String sendOtp = '/api/v1/auth/send';
  static const String verifyOtp = '/api/v1/auth/verify';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // Guests
  static const String guests = '/api/v1/guests';

  // Devices
  static const String currentDevice = '/api/v1/devices/me';

  // Checks
  static const String checks = '/api/v1/checks';
  static const String makeCheck = '/api/v1/checks/make';
  static const String myChecks = '/api/v1/checks/mine';
  static String closeMyCheck(String id) => '/api/v1/checks/mine/$id/close';
  static String deleteMyCheck(String id) => '/api/v1/checks/mine/$id';
  static String checkOptionReasons(String checkId, String optionId) =>
      '/api/v1/checks/mine/$checkId/options/$optionId/reasons';
  static String checkCustomAnswers(String checkId) =>
      '/api/v1/checks/mine/$checkId/custom-answers';
  static String pollCustomAnswers(String pollId) =>
      '/api/v1/polls/$pollId/custom-answers';
  static String reportCheckReason(String checkId, String reasonId) =>
      '/api/v1/checks/mine/$checkId/reasons/$reasonId/report';

  // Polls (owner)
  static const String createPoll = '/api/v1/polls';
  static const String askedPolls = '/api/v1/polls/asked';
  static const String answeredPolls = '/api/v1/polls/answered';
  static const String savedPolls = '/api/v1/polls/saved';

  static String pollById(String pollId) => '/api/v1/polls/$pollId';

  static String closePoll(String pollId) => '/api/v1/polls/$pollId/close';

  static String pollOptionReasons(String pollId, String optionId) =>
      '/api/v1/polls/$pollId/options/$optionId/reasons';
  static String reportPollReason(String pollId, String reasonId) =>
      '/api/v1/polls/$pollId/reasons/$reasonId/report';
  static String deletePoll(String pollId) => '/api/v1/polls/$pollId';

  static String savePoll(String pollId) => '/api/v1/polls/$pollId/save';

  // Shared content (polls and checks, resolved by share code)
  static String sharedContent(String shareCode) => '/api/v1/shares/$shareCode';

  static const String castVote = '/api/v1/votes';

  // User
  static const String getMe = '/api/v1/users';
  static const String deleteMe = '/api/v1/users/me';

  // Notifications
  static const String notifications = '/api/v1/notifications';

  static const String notificationsUnreadCount = '$notifications/unread-count';
  static const String notificationsReadAll = '$notifications/read-all';
  static String notificationRead(String id) => '$notifications/$id/read';

  // Media upload sessions
  static const String mediaUploadSessions = '/api/v1/media-upload-sessions';

  static String mediaUploadSessionById(String sessionId) =>
      '$mediaUploadSessions/$sessionId';

  static String mediaUploadSessionComplete(String sessionId) =>
      '$mediaUploadSessions/$sessionId/complete';

  static String mediaUploadSessionCancel(String sessionId) =>
      '$mediaUploadSessions/$sessionId/cancel';
}
