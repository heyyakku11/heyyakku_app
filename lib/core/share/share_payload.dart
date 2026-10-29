import 'package:flutter/foundation.dart';
import 'package:yakku/core/constants/api_constants.dart';
import 'package:yakku/core/deep_link/poll_deep_link.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll/poll_response.dart';

/// Why a [SharePayload] could not be built.
enum SharePayloadError {
  invalidShareCode,
  emptyQuestion,
  notPublic,
  invalidBaseUrl,
}

class SharePayloadException implements Exception {
  const SharePayloadException(this.error);

  final SharePayloadError error;

  @override
  String toString() => 'SharePayloadException($error)';
}

/// Immutable description of a poll being shared. Contains only public data:
/// the poll's share code, its question and the canonical public URL.
@immutable
class SharePayload {
  const SharePayload._({
    required this.shareCode,
    required this.question,
    required this.url,
    this.options = const [],
  });

  final String shareCode;
  final String question;

  /// Answer labels (at most [maxOptions]) shown on the story card image.
  final List<String> options;

  static const int maxOptions = 4;

  /// Canonical `https://<website>/vote/{shareCode}` URL; the single link every
  /// platform shares.
  final Uri url;

  /// Builds a payload, throwing [SharePayloadException] when invalid.
  /// [websiteBaseUrl] defaults to [ApiConstants.webBaseUrl], the single
  /// source of truth for the website origin.
  factory SharePayload.create({
    required String shareCode,
    required String question,
    String websiteBaseUrl = ApiConstants.webBaseUrl,
    bool isPublic = true,
    List<String> options = const [],
  }) {
    final code = shareCode.trim();
    final text = question.trim();
    if (!PollDeepLink.isValidShareCode(code)) {
      throw const SharePayloadException(SharePayloadError.invalidShareCode);
    }
    if (text.isEmpty) {
      throw const SharePayloadException(SharePayloadError.emptyQuestion);
    }
    if (!isPublic) {
      throw const SharePayloadException(SharePayloadError.notPublic);
    }
    final base = Uri.tryParse(websiteBaseUrl.trim());
    final host = base?.host.toLowerCase() ?? '';
    final isLocal =
        host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
    if (base == null || base.scheme != 'https' || host.isEmpty || isLocal) {
      throw const SharePayloadException(SharePayloadError.invalidBaseUrl);
    }
    final url = Uri(
      scheme: 'https',
      host: base.host,
      port: base.hasPort ? base.port : null,
      pathSegments: [
        ...base.pathSegments.where((s) => s.isNotEmpty),
        'vote',
        code,
      ],
    );
    return SharePayload._(
      shareCode: code,
      question: text,
      url: url,
      options: List.unmodifiable(
        options
            .map((o) => o.trim())
            .where((o) => o.isNotEmpty)
            .take(maxOptions),
      ),
    );
  }

  factory SharePayload.fromPollModel(
    PollModel poll, {
    String websiteBaseUrl = ApiConstants.webBaseUrl,
  }) => SharePayload.create(
    shareCode: poll.shareCode,
    question: poll.question,
    websiteBaseUrl: websiteBaseUrl,
  );

  factory SharePayload.fromPollResponse(
    PollResponse poll, {
    String websiteBaseUrl = ApiConstants.webBaseUrl,
  }) => SharePayload.create(
    shareCode: poll.shareCode,
    question: poll.question,
    websiteBaseUrl: websiteBaseUrl,
    isPublic: poll.visibility.toLowerCase() != 'private',
    options: poll.options.map((o) => o.text ?? '').toList(),
  );
}
