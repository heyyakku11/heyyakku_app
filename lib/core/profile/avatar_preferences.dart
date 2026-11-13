import 'package:flutter/material.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';

/// One of the background colours a user can give their avatar.
@immutable
class AvatarColor {
  const AvatarColor(this.id, this.color);

  /// Stable name saved in preferences (never the colour value, so the palette
  /// can be tuned later without losing anyone's choice).
  final String id;
  final Color color;
}

abstract final class AvatarColors {
  static const pink = AvatarColor('pink', Color(0xFFF7B9CB));
  static const lavender = AvatarColor('lavender', Color(0xFFECE3FF));
  static const mint = AvatarColor('mint', Color(0xFFD7F1E2));
  static const yellow = AvatarColor('yellow', Color(0xFFFFEBBE));
  static const blue = AvatarColor('blue', Color(0xFFBBDFFC));
  static const peach = AvatarColor('peach', Color(0xFFFFC8A5));

  /// In the order they are offered.
  static const all = [pink, lavender, mint, yellow, blue, peach];

  /// Lavender until the user picks another.
  static const defaultColor = lavender;

  static AvatarColor byId(String? id) {
    for (final option in all) {
      if (option.id == id) return option;
    }
    return defaultColor;
  }
}

/// The avatar background colour, kept on this device only.
class AvatarPreferences {
  AvatarPreferences({PreferenceStorageService? storage})
    : _storage = storage ?? PreferenceStorageService();

  final PreferenceStorageService _storage;

  /// The colour most recently saved in this session, so every avatar on screen (profile, home header) follows a
  /// change at once. Null until a colour is saved; screens then keep what they loaded.
  static final ValueNotifier<AvatarColor?> changes =
      ValueNotifier<AvatarColor?>(null);

  Future<AvatarColor> load() async {
    try {
      return AvatarColors.byId(await _storage.read(StorageKeys.avatarColor));
    } catch (_) {
      return AvatarColors.defaultColor;
    }
  }

  Future<void> save(AvatarColor color) async {
    changes.value = color;
    try {
      await _storage.update(StorageKeys.avatarColor, color.id);
    } catch (_) {
      // The colour just won't survive a restart.
    }
  }
}
