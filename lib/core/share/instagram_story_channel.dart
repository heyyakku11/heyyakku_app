import 'package:flutter/services.dart';

/// Meta (Facebook) App ID that Instagram requires as `source_application` when
/// a Story is shared. Supply the real one at build time:
///
///   flutter run --dart-define=META_APP_ID=1234567890
///
/// Until then [metaAppId] is a placeholder and the feature is NOT ready for
/// production. See docs/instagram_story_sharing.md.
abstract final class InstagramStoryConfig {
  static const String placeholderAppId = 'YOUR_META_APP_ID';

  static const String metaAppId = String.fromEnvironment(
    'META_APP_ID',
    defaultValue: placeholderAppId,
  );

  static bool get isConfigured =>
      metaAppId.isNotEmpty && metaAppId != placeholderAppId;
}

enum InstagramStoryOutcome {
  /// Instagram's Story composer was opened with the image.
  opened,

  /// Instagram isn't installed (or can't handle the Story intent).
  notInstalled,
}

/// Native bridge to Instagram's Story composer. Android sends the
/// `com.instagram.share.ADD_TO_STORY` intent; iOS writes the image to the
/// pasteboard and opens `instagram-stories://share`.
class InstagramStoryChannel {
  const InstagramStoryChannel();

  static const MethodChannel _channel = MethodChannel(
    'com.example.yakku/instagram_story',
  );

  /// Opens the Story composer with the PNG at [imagePath] as the background.
  /// [linkText] is kept on the iOS pasteboard next to the image so the user can
  /// still paste it. Throws [PlatformException] if the native side fails.
  Future<InstagramStoryOutcome> shareToStory({
    required String imagePath,
    required String linkText,
    String appId = InstagramStoryConfig.metaAppId,
  }) async {
    final status = await _channel.invokeMethod<String>('shareToStory', {
      'imagePath': imagePath,
      'linkText': linkText,
      'appId': appId,
    });
    return switch (status) {
      'opened' => InstagramStoryOutcome.opened,
      'notInstalled' => InstagramStoryOutcome.notInstalled,
      _ => throw PlatformException(
        code: 'unexpected_result',
        message: 'Unexpected native result: $status',
      ),
    };
  }
}
