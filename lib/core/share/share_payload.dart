import 'package:flutter/foundation.dart';
import 'package:yakku/core/constants/api_constants.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll/poll_response.dart';

/// Why a [SharePayload] could not be built.
enum SharePayloadError {
  invalidPollId,
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
/// the poll id, its question and the canonical public URL.
@immutable
class SharePayload {
  const SharePayload._({
    required this.pollId,
    required this.question,
    required this.url,
  });

  final String pollId;
  final String question;

  /// Canonical `https://<website>/vote/{pollId}` URL; the single link every
  /// platform shares.
  final Uri url;

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Builds a payload, throwing [SharePayloadException] when invalid.
  /// [websiteBaseUrl] defaults to [ApiConstants.webBaseUrl], the single
  /// source of truth for the website origin.
  factory SharePayload.create({
    required String pollId,
    required String question,
    String websiteBaseUrl = ApiConstants.webBaseUrl,
    bool isPublic = true,
  }) {
    final id = pollId.trim();
    final text = question.trim();
    if (!_uuid.hasMatch(id)) {
      throw const SharePayloadException(SharePayloadError.invalidPollId);
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
        id.toLowerCase(),
      ],
    );
    return SharePayload._(pollId: id.toLowerCase(), question: text, url: url);
  }

  factory SharePayload.fromPollModel(
    PollModel poll, {
    String websiteBaseUrl = ApiConstants.webBaseUrl,
  }) => SharePayload.create(
    pollId: poll.id,
    question: poll.question,
    websiteBaseUrl: websiteBaseUrl,
  );

  factory SharePayload.fromPollResponse(
    PollResponse poll, {
    String websiteBaseUrl = ApiConstants.webBaseUrl,
  }) => SharePayload.create(
    pollId: poll.id,
    question: poll.question,
    websiteBaseUrl: websiteBaseUrl,
    isPublic: poll.visibility.toLowerCase() != 'private',
  );
}
