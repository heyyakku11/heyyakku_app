import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/share/share_result.dart';

typedef ClipboardWriter = Future<void> Function(String text);

Future<void> _writeClipboard(String text) =>
    Clipboard.setData(ClipboardData(text: text));

/// Copies only the canonical public poll URL.
class CopyLinkShareAdapter extends SharePlatformAdapter {
  // ignore: prefer_initializing_formals
  const CopyLinkShareAdapter({ClipboardWriter writer = _writeClipboard})
    : _writer = writer;

  final ClipboardWriter _writer;

  @override
  SharePlatformId get id => SharePlatformId.copyLink;
  @override
  String get displayName => 'Copy link';
  @override
  IconData get icon => Icons.link_rounded;
  @override
  Color get brandColor => const Color(0xFF1B1418);

  @override
  Future<ShareResult> share(SharePayload payload) async {
    try {
      await _writer(payload.url.toString());
      return const ShareSuccess(feedbackMessage: 'Link copied');
    } catch (e) {
      debugPrint('Copy link failed: $e');
      return const ShareFailure(
        ShareFailureReason.clipboardFailed,
        userMessage: "Couldn't copy the link. Please try again.",
      );
    }
  }
}
