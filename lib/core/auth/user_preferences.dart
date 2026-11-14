import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';

class UserPreferences {
  UserPreferences({PreferenceStorageService? storage})
    : _storage = storage ?? PreferenceStorageService();

  final PreferenceStorageService _storage;

  static const isUserLoggedKey = StorageKeys.isUserLogged;

  Future<bool> getIsUserLogged() async {
    return await _storage.readBool(StorageKeys.isUserLogged) ?? false;
  }

  Future<void> setIsUserLogged(bool value) async {
    await _storage.updateBool(StorageKeys.isUserLogged, value);
  }

  /// False until the user finishes or skips onboarding. Missing key means false.
  /// Not cleared by [clearAuth], so logout still opens sign-up.
  Future<bool> getHasCompletedOnboarding() async {
    return await _storage.readBool(StorageKeys.hasCompletedOnboarding) ?? false;
  }

  Future<void> setHasCompletedOnboarding(bool value) async {
    await _storage.updateBool(StorageKeys.hasCompletedOnboarding, value);
  }

  Future<String?> getPhoneNumber() async {
    final phone = await _storage.read(StorageKeys.phoneNumber);
    if (phone != null && phone.isNotEmpty) return phone;

    // Migrate values previously stored under the email key.
    final legacy = await _storage.read(StorageKeys.legacyEmail);
    if (legacy == null || legacy.isEmpty) return null;
    await setPhoneNumber(legacy);
    await _storage.delete(StorageKeys.legacyEmail);
    return legacy;
  }

  Future<void> setPhoneNumber(String phoneNumber) async {
    await _storage.update(StorageKeys.phoneNumber, phoneNumber);
  }

  Future<String?> getDisplayName() async {
    return _storage.read(StorageKeys.displayName);
  }

  Future<void> setDisplayName(String displayName) async {
    await _storage.update(StorageKeys.displayName, displayName);
  }

  /// Whether the signed-in user asked to be notified when the community opens. Set from the login
  /// response and after tapping "Notify me"; false when never set.
  Future<bool> getCommunityNotifyRequested() async {
    return await _storage.readBool(StorageKeys.communityNotifyMe) ?? false;
  }

  Future<void> setCommunityNotifyRequested(bool value) async {
    await _storage.updateBool(StorageKeys.communityNotifyMe, value);
  }

  Future<void> clearAuth() async {
    await _storage.delete(StorageKeys.phoneNumber);
    await _storage.delete(StorageKeys.legacyEmail);
    await _storage.delete(StorageKeys.displayName);
    await _storage.delete(StorageKeys.communityNotifyMe);
    await _storage.updateBool(StorageKeys.isUserLogged, false);
    // hasCompletedOnboarding is intentionally left set. Onboarding is once
    // per install, not once per account.
  }
}
