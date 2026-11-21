import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';

/// Tracks which cards have already shown the one-time "results are ready"
/// celebration (confetti). Keyed by notification `contentId` so each poll,
/// check, and personality card celebrates at most once on this device.
class CardResultsCelebrationStore {
  CardResultsCelebrationStore({PreferenceStorageService? prefs})
    : _prefs = prefs ?? PreferenceStorageService();

  final PreferenceStorageService _prefs;

  Future<bool> hasSeen(String contentId) async {
    final id = contentId.trim();
    if (id.isEmpty) return false;
    final seen = await _prefs.readStringList(
      StorageKeys.seenCardResultsCelebrations,
    );
    return seen.contains(id);
  }

  /// Marks the card as celebrated. Safe to call repeatedly.
  Future<void> markSeen(String contentId) async {
    final id = contentId.trim();
    if (id.isEmpty) return;
    final seen = await _prefs.readStringList(
      StorageKeys.seenCardResultsCelebrations,
    );
    if (seen.contains(id)) return;
    await _prefs.updateStringList(StorageKeys.seenCardResultsCelebrations, [
      ...seen,
      id,
    ]);
  }

  /// Returns true only the first time for [contentId], and marks it seen.
  Future<bool> claimFirstWatch(String contentId) async {
    if (await hasSeen(contentId)) return false;
    await markSeen(contentId);
    return true;
  }
}
