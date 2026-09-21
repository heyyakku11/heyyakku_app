import 'package:uuid/uuid.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';

/// Persists a stable app-installation UUID across launches (not cleared on logout).
class InstallationIdStore {
  InstallationIdStore({PreferenceStorageService? storage, Uuid? uuid})
    : _storage = storage ?? PreferenceStorageService(),
      _uuid = uuid ?? const Uuid();

  final PreferenceStorageService _storage;
  final Uuid _uuid;

  Future<String> getOrCreate() async {
    final existing = await _storage.read(StorageKeys.installationId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final id = _uuid.v4();
    await _storage.update(StorageKeys.installationId, id);
    return id;
  }
}
