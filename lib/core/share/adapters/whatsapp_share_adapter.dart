import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Opens WhatsApp's share flow with the question and public link prefilled.
/// The user picks a recipient and sends manually; nothing is sent here.
///
/// Uses `https://wa.me/?text=`: opens the WhatsApp app when installed, and
/// falls back to WhatsApp Web in the browser otherwise.
class WhatsAppShareAdapter extends SharePlatformAdapter {
  const WhatsAppShareAdapter({ExternalUrlLauncher launcher = _launchExternally})
    : _launcher = launcher; // ignore: prefer_initializing_formals

  final ExternalUrlLauncher _launcher;

  static const _failure = ShareFailure(
    ShareFailureReason.launchFailed,
    userMessage: "Couldn't open WhatsApp. Try Copy link instead.",
  );

  @override
  SharePlatformId get id => SharePlatformId.whatsapp;
  @override
  String get displayName => 'WhatsApp';
  @override
  IconData get icon => Icons.chat_rounded;
  @override
  Color get brandColor => const Color(0xFF25D366);

  static String formatMessage(SharePayload payload) =>
      '${payload.question}\n\nVote here: ${payload.url}';

  static Uri buildUri(SharePayload payload) => Uri.parse(
    'https://wa.me/?text=${Uri.encodeComponent(formatMessage(payload))}',
  );

  @override
  Future<ShareResult> share(SharePayload payload) async {
    try {
      final opened = await _launcher(buildUri(payload));
      return opened ? const ShareSuccess() : _failure;
    } catch (e) {
      debugPrint('WhatsApp share failed: $e');
      return _failure;
    }
  }
}
