abstract final class StorageKeys {
  // Secure storage
  static const accessToken = 'accessToken';
  static const refreshToken = 'refreshToken';

  // Preferences
  static const isUserLogged = 'isUserLogged';
  static const hasEnteredAsGuest = 'hasEnteredAsGuest';
  static const email = 'email';
  static const displayName = 'displayName';
  static const installationId = 'installationId';
  static const isNotificationAllowed = 'isNotificationAllowed';
  static const notificationPermissionAsked = 'notificationPermissionAsked';

  // You tab settings kept on device (not sent to the server).
  static const notifyVotesAndReasons = 'notifyVotesAndReasons';
  static const notifyResultReady = 'notifyResultReady';
  static const notifyFriendsAsked = 'notifyFriendsAsked';
  static const notifyWeeklyDrop = 'notifyWeeklyDrop';
  static const privacyTellVoters = 'privacyTellVoters';
  static const privacyKindMode = 'privacyKindMode';
}
