import 'package:flutter/material.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_result.dart';

/// Stable identifier for a share destination. A value class (not an enum) so
/// new platforms can be added without editing existing code.
@immutable
class SharePlatformId {
  const SharePlatformId(this.value);

  static const whatsapp = SharePlatformId('whatsapp');
  static const instagramDm = SharePlatformId('instagram_dm');
  static const instagramStory = SharePlatformId('instagram_story');
  static const copyLink = SharePlatformId('copy_link');

  final String value;

  @override
  bool operator ==(Object other) =>
      other is SharePlatformId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// One share destination. Implementations own everything platform-specific:
/// URI/deep-link construction, capability checks, SDK calls and fallbacks.
abstract class SharePlatformAdapter {
  const SharePlatformAdapter();

  SharePlatformId get id;
  String get displayName;

  /// Presentation hints used by the generic share sheet.
  IconData get icon;
  Color get brandColor;
  Color get onBrandColor => Colors.white;

  /// Whether the destination should be offered for [payload]. Return false to
  /// hide it (e.g. app not installed, payload lacks required media).
  Future<bool> isAvailable(SharePayload payload) async => true;

  Future<ShareResult> share(SharePayload payload);
}
