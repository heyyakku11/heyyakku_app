abstract final class StorageKeys {
  // Secure storage
  static const accessToken = 'accessToken';
  static const refreshToken = 'refreshToken';
  static const guestToken = 'guestToken';
  static const guestId = 'guestId';
  static const guestExpiresAt = 'guestExpiresAt';

  // Preferences
  static const isUserLogged = 'isUserLogged';
  static const hasEnteredAsGuest = 'hasEnteredAsGuest';
  static const phoneNumber = 'phoneNumber';

  /// The avatar background colour chosen on the edit-profile screen.
  static const avatarColor = 'avatarColor';

  /// Legacy prefs key; kept for one-time migration to [phoneNumber].
  static const legacyEmail = 'email';
  static const displayName = 'displayName';
  static const installationId = 'installationId';
  static const isNotificationAllowed = 'isNotificationAllowed';
  static const notificationPermissionAsked = 'notificationPermissionAsked';

  // You tab privacy settings kept on device (not sent to the server).
  static const privacyTellVoters = 'privacyTellVoters';
  static const privacyKindMode = 'privacyKindMode';

  /// "Notify me when it opens" on the Community placeholder (device only).
  static const communityNotifyMe = 'communityNotifyMe';
}
