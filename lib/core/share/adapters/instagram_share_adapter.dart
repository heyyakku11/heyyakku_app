import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yakku/core/share/instagram_story_channel.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';
import 'package:yakku/core/share/story_image_service.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);
typedef ClipboardWriter = Future<void> Function(String text);

/// Renders the story card for [question] and [options] to a temp PNG.
typedef StoryImageRenderer =
    Future<File> Function(String question, List<String> options);

/// Hands the PNG to Instagram's Story composer.
typedef InstagramStorySharer =
    Future<InstagramStoryOutcome> Function({
      required String imagePath,
      required String linkText,
    });

Future<bool> _launchExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

Future<void> _writeClipboard(String text) =>
    Clipboard.setData(ClipboardData(text: text));

final StoryImageService _storyImages = StoryImageService();

Future<File> _defaultRenderStoryImage(String question, List<String> options) =>
    _storyImages.render(question: question, options: options);

Future<InstagramStoryOutcome> _shareStoryNatively({
  required String imagePath,
  required String linkText,
}) => const InstagramStoryChannel().shareToStory(
  imagePath: imagePath,
  linkText: linkText,
);

/// Where inside Instagram the user lands.
enum InstagramDestination {
  /// Direct-message inbox, to pick a friend and paste the link.
  inbox,

  /// Story composer, preloaded with the Yakku card image.
  story,
}

/// Opens Instagram at [destination] after copying the public poll link to the
/// clipboard (Instagram offers no way to prefill text), so the user can paste
/// it. Nothing is posted or sent here.
///
/// For [InstagramDestination.story] the Yakku card is rendered to a 1080x1920
/// PNG and passed to Instagram's Story composer. The copied link is *not*
/// turned into a Link sticker automatically; the user adds one and pastes it.
class InstagramShareAdapter extends SharePlatformAdapter {
  const InstagramShareAdapter(
    this.destination, {
    ExternalUrlLauncher launcher = _launchExternally,
    ClipboardWriter clipboard = _writeClipboard,
    StoryImageRenderer renderStoryImage = _defaultRenderStoryImage,
    InstagramStorySharer storySharer = _shareStoryNatively,
  }) : _launcher = launcher,
       _clipboard = clipboard,
       _renderStoryImage = renderStoryImage,
       _storySharer = storySharer;

  final InstagramDestination destination;
  final ExternalUrlLauncher _launcher;
  final ClipboardWriter _clipboard;
  final StoryImageRenderer _renderStoryImage;
  final InstagramStorySharer _storySharer;

  @override
  SharePlatformId get id => destination == InstagramDestination.inbox
      ? SharePlatformId.instagramDm
      : SharePlatformId.instagramStory;
  @override
  String get displayName => destination == InstagramDestination.inbox
      ? 'Instagram'
      : 'Instagram Story';
  @override
  IconData get icon => Icons.photo_camera_outlined;
  @override
  Color get brandColor => YakkuPalette.instagramPink;

  static const String _openFailedMessage =
      "Couldn't open Instagram. Try Copy link instead.";

  /// Web URL, which universal-links into the app when installed and otherwise
  /// opens in the browser.
  List<Uri> get _targets => switch (destination) {
    InstagramDestination.inbox => [
      Uri.parse('https://www.instagram.com/direct/inbox/'),
    ],
    InstagramDestination.story => [Uri.parse('https://www.instagram.com/')],
  };

  @override
  Future<ShareResult> share(SharePayload payload) async {
    await _copyLink(payload);
    if (destination == InstagramDestination.story) {
      return _shareStory(payload);
    }
    return _openInstagram();
  }

  Future<void> _copyLink(SharePayload payload) async {
    try {
      await _clipboard(payload.url.toString());
    } catch (e) {
      debugPrint('Instagram share: clipboard failed: $e');
    }
  }

  Future<ShareResult> _openInstagram() async {
    for (final uri in _targets) {
      try {
        if (await _launcher(uri)) {
          return const ShareSuccess(
            feedbackMessage: 'Link copied. Paste it in Instagram.',
          );
        }
      } catch (e) {
        debugPrint('Instagram share: launch $uri failed: $e');
      }
    }
    return const ShareFailure(
      ShareFailureReason.launchFailed,
      userMessage: _openFailedMessage,
    );
  }

  Future<ShareResult> _shareStory(SharePayload payload) async {
    if (!InstagramStoryConfig.isConfigured) {
      debugPrint(
        'Instagram share: META_APP_ID is not set. Pass '
        '--dart-define=META_APP_ID=<id>; Instagram may reject the Story.',
      );
    }
    try {
      final image = await _renderStoryImage(payload.question, payload.options);
      debugPrint(
        'Instagram share: story image ready path=${image.path} '
        'bytes=${image.lengthSync()}',
      );
      // Deliberately not deleted here: Instagram reads the file asynchronously
      // after the intent launches. The next render clears stale files.
      final outcome = await _storySharer(
        imagePath: image.path,
        linkText: payload.url.toString(),
      );
      debugPrint('Instagram share: native outcome=$outcome');
      return switch (outcome) {
        InstagramStoryOutcome.opened => const ShareSuccess(
          feedbackMessage: 'Link copied. Add a Link sticker to your story.',
        ),
        InstagramStoryOutcome.notInstalled => const ShareFailure(
          ShareFailureReason.launchFailed,
          userMessage:
              "Instagram isn't installed. The link is copied, "
              'so you can paste it anywhere.',
        ),
      };
    } on StoryImageException catch (e, st) {
      debugPrint('Instagram share: story image failed: $e\n$st');
      return const ShareFailure(
        ShareFailureReason.unknown,
        userMessage: "Couldn't create the story image. The link is copied.",
      );
    } on PlatformException catch (e, st) {
      debugPrint(
        'Instagram share: native failed code=${e.code} '
        'message=${e.message}\n$st',
      );
      return ShareFailure(
        ShareFailureReason.launchFailed,
        userMessage:
            "Couldn't open the Instagram Story (${e.code}). "
            'The link is copied.',
      );
    } catch (e, st) {
      debugPrint('Instagram share: unexpected failure: $e\n$st');
      return const ShareFailure(
        ShareFailureReason.unknown,
        userMessage: "Couldn't open the Instagram Story. The link is copied.",
      );
    }
  }
}
