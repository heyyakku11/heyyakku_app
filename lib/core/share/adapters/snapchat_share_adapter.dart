import 'package:flutter/material.dart';
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

/// Opens Snapchat's camera with the public poll link attached as a link
/// sticker. The link is also copied to the clipboard as a backup. Nothing is
/// posted or sent here.
///
/// Uses `https://www.snapchat.com/scan?attachmentUrl=`: opens the Snapchat app
/// when installed and falls back to the Snapchat web page in the browser.
class SnapchatShareAdapter extends SharePlatformAdapter {
  const SnapchatShareAdapter({
    ExternalUrlLauncher launcher = _launchExternally,
    ClipboardWriter clipboard = _writeClipboard,
  }) : _launcher = launcher,
       _clipboard = clipboard;

  final ExternalUrlLauncher _launcher;
  final ClipboardWriter _clipboard;

  static const _failure = ShareFailure(
    ShareFailureReason.launchFailed,
    userMessage: "Couldn't open Snapchat. Try Copy link instead.",
  );

  @override
  SharePlatformId get id => SharePlatformId.snapchat;
  @override
  String get displayName => 'Snapchat';
  @override
  IconData get icon => Icons.chat_bubble_outline_rounded;
  @override
  Color get brandColor => const Color(0xFFFFFC00);
  @override
  Color get onBrandColor => Colors.black;

  static Uri buildUri(SharePayload payload) => Uri.parse(
    'https://www.snapchat.com/scan'
    '?attachmentUrl=${Uri.encodeComponent(payload.url.toString())}',
  );

  @override
  Future<ShareResult> share(SharePayload payload) async {
    try {
      await _clipboard(payload.url.toString());
    } catch (e) {
      debugPrint('Snapchat share: clipboard failed: $e');
    }
    try {
      final opened = await _launcher(buildUri(payload));
      return opened
          ? const ShareSuccess(
              feedbackMessage: 'Link copied. Paste it in Snapchat if needed.',
            )
          : _failure;
    } catch (e) {
      debugPrint('Snapchat share failed: $e');
      return _failure;
    }
  }
}
