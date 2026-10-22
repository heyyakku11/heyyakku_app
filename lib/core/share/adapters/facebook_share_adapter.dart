import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Opens Facebook's share dialog with the public poll link prefilled. The user
/// confirms and posts manually; nothing is posted here.
///
/// Uses `https://www.facebook.com/sharer/sharer.php?u=`: opens the Facebook app
/// when installed and falls back to the Facebook web share page in the browser.
class FacebookShareAdapter extends SharePlatformAdapter {
  const FacebookShareAdapter({ExternalUrlLauncher launcher = _launchExternally})
    : _launcher = launcher; // ignore: prefer_initializing_formals

  final ExternalUrlLauncher _launcher;

  static const _failure = ShareFailure(
    ShareFailureReason.launchFailed,
    userMessage: "Couldn't open Facebook. Try Copy link instead.",
  );

  @override
  SharePlatformId get id => SharePlatformId.facebook;
  @override
  String get displayName => 'Facebook';
  @override
  IconData get icon => Icons.facebook_rounded;
  @override
  Color get brandColor => const Color(0xFF1877F2);

  static Uri buildUri(SharePayload payload) => Uri.parse(
    'https://www.facebook.com/sharer/sharer.php'
    '?u=${Uri.encodeComponent(payload.url.toString())}',
  );

  @override
  Future<ShareResult> share(SharePayload payload) async {
    try {
      final opened = await _launcher(buildUri(payload));
      return opened ? const ShareSuccess() : _failure;
    } catch (e) {
      debugPrint('Facebook share failed: $e');
      return _failure;
    }
  }
}
