import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _memory = null;

  /// In-memory backend for tests (avoids platform secure storage).
  SecureStorageService.inMemory([Map<String, String>? store])
      : _storage = null,
        _memory = store ?? <String, String>{};

  final FlutterSecureStorage? _storage;
  final Map<String, String>? _memory;

  bool get _useMemory => _memory != null;

  Future<bool> exists(String key) async {
    if (_useMemory) {
      return _memory!.containsKey(key);
    }
    return _storage!.containsKey(key: key);
  }

  Future<String?> read(String key) async {
    if (_useMemory) {
      return _memory![key];
    }
    return _storage!.read(key: key);
  }

  /// Writes only if the key does not already exist.
  Future<void> create(String key, String value) async {
    if (await exists(key)) {
      throw StateError('Secure storage key "$key" already exists');
    }
    await update(key, value);
  }

  Future<void> update(String key, String value) async {
    if (_useMemory) {
      _memory![key] = value;
      return;
    }
    await _storage!.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    if (_useMemory) {
      _memory!.remove(key);
      return;
    }
    await _storage!.delete(key: key);
  }

  Future<void> clearKeys(List<String> keys) async {
    for (final key in keys) {
      await delete(key);
    }
  }
}
