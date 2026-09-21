import 'package:shared_preferences/shared_preferences.dart';

class PreferenceStorageService {
  PreferenceStorageService({SharedPreferences? this._prefs});

  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> exists(String key) async {
    final prefs = await _instance();
    return prefs.containsKey(key);
  }

  Future<String?> read(String key) async {
    final prefs = await _instance();
    return prefs.getString(key);
  }

  Future<bool?> readBool(String key) async {
    final prefs = await _instance();
    return prefs.getBool(key);
  }

  /// Writes only if the key does not already exist.
  Future<void> create(String key, String value) async {
    if (await exists(key)) {
      throw StateError('Preference key "$key" already exists');
    }
    final prefs = await _instance();
    await prefs.setString(key, value);
  }

  Future<void> createBool(String key, bool value) async {
    if (await exists(key)) {
      throw StateError('Preference key "$key" already exists');
    }
    final prefs = await _instance();
    await prefs.setBool(key, value);
  }

  Future<void> update(String key, String value) async {
    final prefs = await _instance();
    await prefs.setString(key, value);
  }

  Future<void> updateBool(String key, bool value) async {
    final prefs = await _instance();
    await prefs.setBool(key, value);
  }

  Future<void> delete(String key) async {
    final prefs = await _instance();
    await prefs.remove(key);
  }

  Future<void> clearAuthPrefs({required List<String> keys}) async {
    final prefs = await _instance();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
