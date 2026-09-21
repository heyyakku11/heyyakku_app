abstract final class ApiRoutes {
  // Auth
  static const String sendOtp = '/api/v1/auth/send-otp';
  static const String verifyOtp = '/api/v1/auth/verify-otp';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // Devices
  static const String registerDevice = '/api/v1/devices/register';

  // Polls
  static const String createPoll = '/api/v1/polls';

  static String castVote(String pollId) => '/api/v1/polls/$pollId/votes';

  // User
  static const String getMe = '/api/v1/users';
  static const String askedPolls = '/api/v1/users/asked-polls';
  static const String answeredPolls = '/api/v1/users/answered-polls';

  static String viewPoll(String pollId) => '/api/v1/users/view-poll/$pollId';

  static String closePoll(String pollId) =>
      '/api/v1/users/close-poll/$pollId/close';

  static String deletePoll(String pollId) =>
      '/api/v1/users/delete-poll/$pollId';

  // Notifications
  static const String notifications = '/api/v1/notifications';

  static String markNotificationRead(String id) =>
      '/api/v1/notifications/$id/read';
}
