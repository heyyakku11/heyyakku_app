import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';

class YouSettings {
  const YouSettings({
    required this.tellVoters,
    required this.kindMode,
  });

  final bool tellVoters;
  final bool kindMode;

  static const defaults = YouSettings(
    tellVoters: true,
    kindMode: false,
  );

  YouSettings copyWith({
    bool? tellVoters,
    bool? kindMode,
  }) {
    return YouSettings(
      tellVoters: tellVoters ?? this.tellVoters,
      kindMode: kindMode ?? this.kindMode,
    );
  }
}

/// Privacy switches from the You tab. Stored locally only.
class YouSettingsStore {
  YouSettingsStore({PreferenceStorageService? storage})
    : _storage = storage ?? PreferenceStorageService();

  final PreferenceStorageService _storage;

  Future<YouSettings> load() async {
    return YouSettings(
      tellVoters: await _read(
        StorageKeys.privacyTellVoters,
        YouSettings.defaults.tellVoters,
      ),
      kindMode: await _read(
        StorageKeys.privacyKindMode,
        YouSettings.defaults.kindMode,
      ),
    );
  }

  Future<void> save(YouSettings settings) async {
    await _storage.updateBool(
      StorageKeys.privacyTellVoters,
      settings.tellVoters,
    );
    await _storage.updateBool(StorageKeys.privacyKindMode, settings.kindMode);
  }

  Future<bool> _read(String key, bool fallback) async {
    return await _storage.readBool(key) ?? fallback;
  }
}
