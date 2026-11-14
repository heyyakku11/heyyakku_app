abstract final class StorageKeys {
  // Secure storage
  static const accessToken = 'accessToken';
  static const refreshToken = 'refreshToken';

  // Preferences
  static const isUserLogged = 'isUserLogged';
  static const phoneNumber = 'phoneNumber';

  /// Set once the user finishes or skips onboarding. Stays true across logout.
  static const hasCompletedOnboarding = 'hasCompletedOnboarding';

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
