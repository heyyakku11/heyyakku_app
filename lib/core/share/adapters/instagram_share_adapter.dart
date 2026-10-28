import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);
typedef ClipboardWriter = Future<void> Function(String text);

Future<bool> _launchExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

Future<void> _writeClipboard(String text) =>
    Clipboard.setData(ClipboardData(text: text));

/// Where inside Instagram the user lands.
enum InstagramDestination {
  /// Direct-message inbox, to pick a friend and paste the link.
  inbox,

  /// Story camera/composer, to post the link as a link sticker.
  story,
}

/// Opens Instagram at [destination] after copying the public poll link to the
/// clipboard (Instagram offers no way to prefill text), so the user can paste
/// it. Nothing is posted or sent here.
class InstagramShareAdapter extends SharePlatformAdapter {
  const InstagramShareAdapter(
    this.destination, {
    ExternalUrlLauncher launcher = _launchExternally,
    ClipboardWriter clipboard = _writeClipboard,
  }) : _launcher = launcher,
       _clipboard = clipboard;

  final InstagramDestination destination;
  final ExternalUrlLauncher _launcher;
  final ClipboardWriter _clipboard;

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

  /// App deep link first, then the web URL (which universal-links into the app
  /// when installed and otherwise opens in the browser).
  List<Uri> get _targets => switch (destination) {
    InstagramDestination.inbox => [
      Uri.parse('https://www.instagram.com/direct/inbox/'),
    ],
    InstagramDestination.story => [
      Uri.parse('instagram://story-camera'),
      Uri.parse('https://www.instagram.com/'),
    ],
  };

  @override
  Future<ShareResult> share(SharePayload payload) async {
    try {
      await _clipboard(payload.url.toString());
    } catch (e) {
      debugPrint('Instagram share: clipboard failed: $e');
    }
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
      userMessage: "Couldn't open Instagram. Try Copy link instead.",
    );
  }
}
