abstract final class ApiRoutes {
  // Auth
  static const String sendOtp = '/api/v1/auth/send-otp';
  static const String verifyOtp = '/api/v1/auth/verify-otp';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';
  static const String logoutAll = '/api/v1/auth/logout-all';

  // Devices
  static const String registerDevice = '/api/v1/devices/register';

  // Polls
  static const String polls = '/api/v1/polls';
  static const String createPoll = '/api/v1/users/poll/create';
  static const String castVote = '/api/v1/polls/vote';

  static String pollById(String pollId) => '/api/v1/polls/$pollId';

  static String pollByShareToken(String shareToken) =>
      '/api/v1/polls/share/$shareToken';

  // User
  static const String getMe = '/api/v1/users';
  static const String askedPolls = '/api/v1/users/asked-polls';
  static const String answeredPolls = '/api/v1/users/answered-polls';
  static const String savedPolls = '/api/v1/users/saved-polls';

  static String viewPoll(String pollId) => '/api/v1/users/view-poll/$pollId';

  static String closePoll(String pollId) =>
      '/api/v1/users/close-poll/$pollId/close';

  static String deletePoll(String pollId) =>
      '/api/v1/users/delete-poll/$pollId';

  static String savePoll(String pollId) => '/api/v1/users/save-poll/$pollId';

  // Notifications
  static const String notifications = '/api/v1/users/notifications';

  static String markNotificationRead(String id) =>
      '/api/v1/users/notifications/$id/read';

  // Notification preferences
  static const String notificationPreferences =
      '/api/v1/notification-preferences';

  // Categories (public; no auth header)
  static const String categories = '/api/v1/yakku/categories';
}
