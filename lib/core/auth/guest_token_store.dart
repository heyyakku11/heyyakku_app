import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';
import 'package:yakku/data/models/guest/guest_response.dart';

/// Persists anonymous guest identity for `X-Guest-Token` on media APIs.
///
/// Call [hydrate] once during app startup when guest APIs are needed.
class GuestTokenStore {
  GuestTokenStore({required SecureStorageService secureStorage})
    : _secureStorage = secureStorage;

  final SecureStorageService _secureStorage;

  String? _guestId;
  String? _guestToken;
  DateTime? _expiresAt;
  bool _hydrated = false;

  bool get isHydrated => _hydrated;
  String? get guestId => _guestId;
  String? get guestToken => _guestToken;
  DateTime? get expiresAt => _expiresAt;

  bool get hasGuestToken => _guestToken != null && _guestToken!.isNotEmpty;

  bool get isExpired {
    final expires = _expiresAt;
    if (expires == null) return true;
    return DateTime.now().toUtc().isAfter(expires.toUtc());
  }

  bool get hasValidGuest => hasGuestToken && !isExpired;

  Future<void> hydrate() async {
    _guestId = await _secureStorage.read(StorageKeys.guestId);
    _guestToken = await _secureStorage.read(StorageKeys.guestToken);
    final expiresRaw = await _secureStorage.read(StorageKeys.guestExpiresAt);
    _expiresAt = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);
    _hydrated = true;
  }

  /// Saves guest identity from an API response.
  ///
  /// When [GuestResponse.guestToken] is null (reused cookie session on web),
  /// keeps the previously stored token if still present.
  Future<void> saveFromResponse(GuestResponse response) async {
    _guestId = response.guestId;
    _expiresAt = response.expiresAt;

    final issuedToken = response.guestToken;
    if (issuedToken != null && issuedToken.isNotEmpty) {
      _guestToken = issuedToken;
      await _secureStorage.update(StorageKeys.guestToken, issuedToken);
    }

    await _secureStorage.update(StorageKeys.guestId, response.guestId);
    await _secureStorage.update(
      StorageKeys.guestExpiresAt,
      response.expiresAt.toUtc().toIso8601String(),
    );
    _hydrated = true;
  }

  Future<void> clear() async {
    _guestId = null;
    _guestToken = null;
    _expiresAt = null;
    await _secureStorage.clearKeys([
      StorageKeys.guestId,
      StorageKeys.guestToken,
      StorageKeys.guestExpiresAt,
    ]);
    _hydrated = true;
  }
}
