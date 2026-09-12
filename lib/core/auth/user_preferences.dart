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

  Future<String?> getEmail() async {
    return _storage.read(StorageKeys.email);
  }

  Future<void> setEmail(String email) async {
    await _storage.update(StorageKeys.email, email);
  }

  Future<String?> getDisplayName() async {
    return _storage.read(StorageKeys.displayName);
  }

  Future<void> setDisplayName(String displayName) async {
    await _storage.update(StorageKeys.displayName, displayName);
  }

  Future<void> clearAuth() async {
    await _storage.delete(StorageKeys.email);
    await _storage.delete(StorageKeys.displayName);
    await _storage.updateBool(StorageKeys.isUserLogged, false);
  }
}
