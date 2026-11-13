abstract final class ApiRoutes {
  // Auth
  static const String sendOtp = '/api/v1/auth/send';
  static const String verifyOtp = '/api/v1/auth/verify';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // Devices
  static const String currentDevice = '/api/v1/devices/me';

  // Checks
  static const String checks = '/api/v1/checks';
  static const String makeCheck = '/api/v1/checks/make';
  static const String myChecks = '/api/v1/checks/mine';

  // Just-for-fun cards (no live or expiry date; made the same way as checks)
  static const String funCardTypes = '/api/v1/fun-cards/types';
  static const String savedCards = '/api/v1/saved-cards';
  static String savedCard(String cardType, String id) =>
      '/api/v1/saved-cards/$cardType/$id';
  static String funCardsOfType(String typeId) =>
      '/api/v1/fun-cards/types/$typeId/cards';
  static const String makeFunCard = '/api/v1/fun-cards/make';
  static String closeMyCheck(String id) => '/api/v1/checks/mine/$id/close';
  static String reshareMyCheck(String id) => '/api/v1/checks/mine/$id/reshare';
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

  static String pollById(String pollId) => '/api/v1/polls/$pollId';

  static String closePoll(String pollId) => '/api/v1/polls/$pollId/close';
  static String resharePoll(String pollId) => '/api/v1/polls/$pollId/reshare';

  static String pollOptionReasons(String pollId, String optionId) =>
      '/api/v1/polls/$pollId/options/$optionId/reasons';
  static String reportPollReason(String pollId, String reasonId) =>
      '/api/v1/polls/$pollId/reasons/$reasonId/report';
  static String deletePoll(String pollId) => '/api/v1/polls/$pollId';

  // Shared content (polls and checks, resolved by share code)
  static String sharedContent(String shareCode) => '/api/v1/shares/$shareCode';

  static const String castVote = '/api/v1/votes';

  // User
  static const String getMe = '/api/v1/users';
  static const String deleteMe = '/api/v1/users/me';
  static const String personalityTraits = '/api/v1/personality/traits';
  static const String myPersonalityCard = '/api/v1/personality-cards/me';
  static String personalityResults(String shareCode) =>
      '/api/v1/personality-cards/$shareCode/results';
  static const String personalitySelfAssessment =
      '/api/v1/personality-cards/me/self-assessment';
  static const String mySettings = '/api/v1/users/me/settings';

  /// Asks to be notified when the community goes live.
  static const String communityNotifyMe = '/api/v1/community/notify-me';
  static const String regenerateAnonymousName =
      '/api/v1/users/me/anonymous-name';

  // Notifications
  static const String notifications = '/api/v1/notifications';

  static const String notificationsUnreadCount = '$notifications/unread-count';
  static const String notificationsReadAll = '$notifications/read-all';
  static String notificationRead(String id) => '$notifications/$id/read';

  /// Marks the user's notifications about one card read (`contentType` is poll|check).
  static String notificationsContentRead(
    String contentType,
    String contentId,
  ) => '$notifications/content/$contentType/$contentId/read';

  // Ask back
  static const String askBackConversations = '/api/v1/ask-back/conversations';
  static String askBackConversation(String id) => '$askBackConversations/$id';
  static String askBackMessages(String id) =>
      '$askBackConversations/$id/messages';
  static String askBackRead(String id) => '$askBackConversations/$id/read';
  static String askBackMute(String id) => '$askBackConversations/$id/mute';
  static String askBackClose(String id) => '$askBackConversations/$id/close';
  static String askBackReopen(String id) => '$askBackConversations/$id/reopen';
  static String askBackBlock(String id) => '$askBackConversations/$id/block';
  static String askBackUnblock(String id) =>
      '$askBackConversations/$id/unblock';

  /// SignalR hub for Ask Back real-time events (path only; see [ApiConstants.baseUrl]).
  static const String askBackHub = '/hubs/ask-back';

  // Media upload sessions
  static const String mediaUploadSessions = '/api/v1/media-upload-sessions';

  static String mediaUploadSessionById(String sessionId) =>
      '$mediaUploadSessions/$sessionId';

  static String mediaUploadSessionComplete(String sessionId) =>
      '$mediaUploadSessions/$sessionId/complete';

  static String mediaUploadSessionCancel(String sessionId) =>
      '$mediaUploadSessions/$sessionId/cancel';
}
