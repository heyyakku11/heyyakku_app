import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/data/models/poll/poll_media_response.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/shared_content_response.dart';

class PollResponse {
  final String id;
  final String shareCode;
  final String question;
  final String contentType;
  final String status;
  final String visibility;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final String mediaReadiness;
  final PollMediaResponse? media;
  final int totalVoteCount;
  final int customAnswerCount;
  final int totalWhyCount;

  /// Votes from others needed before results are revealed.
  final int minVotes;

  /// Votes from others so far (the creator's own vote isn't counted).
  final int voteProgress;
  final bool resultsUnlocked;
  final List<PollOptionResponse> options;

  /// The asker's own pick (owner view only): an option id, or the text of a
  /// custom answer when no option was picked.
  final String? yourOptionId;
  final String? yourOptionText;

  /// What the caller may do with this card (shared-link view only): whether
  /// they can vote, already voted, or are blocked. Null when not loaded from
  /// the share-code API.
  final VotingStateResponse? voting;

  /// The caller created this card (shared-link view only).
  final bool isOwner;

  const PollResponse({
    required this.id,
    required this.question,
    required this.contentType,
    required this.status,
    required this.visibility,
    required this.createdAt,
    required this.totalVoteCount,
    required this.options,
    this.expiresAt,
    this.shareCode = '',
    this.mediaReadiness = 'none',
    this.media,
    this.customAnswerCount = 0,
    this.totalWhyCount = 0,
    this.minVotes = AppLimits.minVotesToReveal,
    this.voteProgress = 0,
    this.resultsUnlocked = false,
    this.yourOptionId,
    this.yourOptionText,
    this.voting,
    this.isOwner = false,
  });

  factory PollResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    final rawMedia = json['media'];
    return PollResponse(
      id: json['id']?.toString() ?? '',
      shareCode: json['shareCode'] as String? ?? '',
      question: json['question'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'question',
      status: json['status'] as String? ?? '',
      visibility: json['visibility'] as String? ?? '',
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      mediaReadiness: json['mediaReadiness'] as String? ?? 'none',
      media: rawMedia is Map
          ? PollMediaResponse.fromJson(Map<String, dynamic>.from(rawMedia))
          : null,
      totalVoteCount: _asInt(json['totalVoteCount']),
      customAnswerCount: _asInt(json['customAnswerCount']),
      totalWhyCount: _asInt(json['totalWhyCount']),
      minVotes: _asInt(json['minVotes'], fallback: AppLimits.minVotesToReveal),
      voteProgress: _asInt(json['voteProgress']),
      resultsUnlocked: json['resultsUnlocked'] as bool? ?? false,
      options: rawOptions
          .whereType<Map>()
          .map(
            (item) =>
                PollOptionResponse.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }
}

class PollsPage {
  final List<PollResponse> items;
  final String? nextCursor;
  final bool hasMore;

  const PollsPage({required this.items, this.nextCursor, this.hasMore = false});
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
