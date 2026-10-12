import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';

class YouSettings {
  const YouSettings({
    required this.votesAndReasons,
    required this.resultReady,
    required this.friendsAsked,
    required this.weeklyDrop,
    required this.tellVoters,
    required this.kindMode,
  });

  final bool votesAndReasons;
  final bool resultReady;
  final bool friendsAsked;
  final bool weeklyDrop;
  final bool tellVoters;
  final bool kindMode;

  static const defaults = YouSettings(
    votesAndReasons: true,
    resultReady: true,
    friendsAsked: true,
    weeklyDrop: false,
    tellVoters: true,
    kindMode: false,
  );

  YouSettings copyWith({
    bool? votesAndReasons,
    bool? resultReady,
    bool? friendsAsked,
    bool? weeklyDrop,
    bool? tellVoters,
    bool? kindMode,
  }) {
    return YouSettings(
      votesAndReasons: votesAndReasons ?? this.votesAndReasons,
      resultReady: resultReady ?? this.resultReady,
      friendsAsked: friendsAsked ?? this.friendsAsked,
      weeklyDrop: weeklyDrop ?? this.weeklyDrop,
      tellVoters: tellVoters ?? this.tellVoters,
      kindMode: kindMode ?? this.kindMode,
    );
  }
}

/// Notification and privacy switches from the You tab. Stored locally only.
class YouSettingsStore {
  YouSettingsStore({PreferenceStorageService? storage})
    : _storage = storage ?? PreferenceStorageService();

  final PreferenceStorageService _storage;

  Future<YouSettings> load() async {
    return YouSettings(
      votesAndReasons: await _read(
        StorageKeys.notifyVotesAndReasons,
        YouSettings.defaults.votesAndReasons,
      ),
      resultReady: await _read(
        StorageKeys.notifyResultReady,
        YouSettings.defaults.resultReady,
      ),
      friendsAsked: await _read(
        StorageKeys.notifyFriendsAsked,
        YouSettings.defaults.friendsAsked,
      ),
      weeklyDrop: await _read(
        StorageKeys.notifyWeeklyDrop,
        YouSettings.defaults.weeklyDrop,
      ),
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
      StorageKeys.notifyVotesAndReasons,
      settings.votesAndReasons,
    );
    await _storage.updateBool(
      StorageKeys.notifyResultReady,
      settings.resultReady,
    );
    await _storage.updateBool(
      StorageKeys.notifyFriendsAsked,
      settings.friendsAsked,
    );
    await _storage.updateBool(
      StorageKeys.notifyWeeklyDrop,
      settings.weeklyDrop,
    );
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
