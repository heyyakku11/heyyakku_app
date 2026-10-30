import 'package:yakku/data/models/poll/poll_media_response.dart';
import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';

/// `GET /api/v1/shares/{shareCode}` and `POST /api/v1/votes` response: a poll
/// or a check as the caller sees it.
class SharedContentResponse {
  final String contentType;
  final String contentId;
  final String shareCode;
  final String question;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final bool isOwner;
  final List<SharedOptionResponse> options;
  final VotingStateResponse voting;
  final VoteStatsResponse stats;

  /// `poll.pollType` for a poll (`question`, `image`, ...), null for a check.
  final String? pollType;
  final PollMediaResponse? media;

  const SharedContentResponse({
    required this.contentType,
    required this.contentId,
    required this.shareCode,
    required this.question,
    required this.status,
    required this.createdAt,
    required this.options,
    required this.voting,
    required this.stats,
    this.expiresAt,
    this.isOwner = false,
    this.pollType,
    this.media,
  });

  bool get isCheck => contentType.toUpperCase() == 'CHECK';

  factory SharedContentResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    final rawVoting = json['voting'];
    final rawStats = json['stats'];
    final rawPoll = json['poll'];
    final rawMedia = rawPoll is Map ? rawPoll['media'] : null;
    return SharedContentResponse(
      contentType: json['contentType'] as String? ?? '',
      contentId: json['contentId']?.toString() ?? '',
      shareCode: json['shareCode'] as String? ?? '',
      question: json['question'] as String? ?? '',
      status: json['status'] as String? ?? '',
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      isOwner: json['isOwner'] as bool? ?? false,
      options: rawOptions
          .whereType<Map>()
          .map(
            (item) =>
                SharedOptionResponse.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      voting: rawVoting is Map
          ? VotingStateResponse.fromJson(Map<String, dynamic>.from(rawVoting))
          : const VotingStateResponse(),
      stats: rawStats is Map
          ? VoteStatsResponse.fromJson(Map<String, dynamic>.from(rawStats))
          : const VoteStatsResponse(),
      pollType: rawPoll is Map ? rawPoll['pollType'] as String? : null,
      media: rawMedia is Map
          ? PollMediaResponse.fromJson(Map<String, dynamic>.from(rawMedia))
          : null,
    );
  }

  /// Adapts the shared view to the poll model the answer/results screens use.
  PollResponse toPollResponse() {
    return PollResponse(
      id: contentId,
      shareCode: shareCode,
      question: question,
      contentType: pollType ?? 'question',
      status: status,
      visibility: '',
      expiresAt: expiresAt,
      createdAt: createdAt,
      media: media,
      mediaReadiness: media == null ? 'none' : 'ready',
      totalVoteCount: stats.totalVotes ?? 0,
      customAnswerCount: stats.customAnswerCount ?? 0,
      totalWhyCount: stats.whyCount ?? 0,
      minVotes: stats.minVotesToReveal,
      voteProgress: stats.voteProgress,
      resultsUnlocked: stats.resultsVisible,
      voting: voting,
      isOwner: isOwner,
      options: [
        for (final option in options)
          PollOptionResponse(
            id: option.id,
            text: option.text,
            sortOrder: option.displayOrder,
            voteCount: option.voteCount ?? 0,
            percentage: option.percentage ?? 0,
            whyCount: option.whyCount ?? 0,
          ),
      ],
    );
  }
}

class SharedOptionResponse {
  final String id;
  final String text;
  final int displayOrder;
  final int? voteCount;
  final double? percentage;
  final int? whyCount;
  final bool isSelected;

  const SharedOptionResponse({
    required this.id,
    required this.text,
    required this.displayOrder,
    this.voteCount,
    this.percentage,
    this.whyCount,
    this.isSelected = false,
  });

  factory SharedOptionResponse.fromJson(Map<String, dynamic> json) {
    return SharedOptionResponse(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      displayOrder: _asInt(json['displayOrder']) ?? 0,
      voteCount: _asInt(json['voteCount']),
      percentage: _asDouble(json['percentage']),
      whyCount: _asInt(json['whyCount']),
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }
}

class VotingStateResponse {
  final bool canVote;
  final bool hasVoted;
  final String? blockedReason;
  final MyVoteResponse? myVote;

  const VotingStateResponse({
    this.canVote = false,
    this.hasVoted = false,
    this.blockedReason,
    this.myVote,
  });

  factory VotingStateResponse.fromJson(Map<String, dynamic> json) {
    final rawVote = json['myVote'];
    return VotingStateResponse(
      canVote: json['canVote'] as bool? ?? false,
      hasVoted: json['hasVoted'] as bool? ?? false,
      blockedReason: json['blockedReason'] as String?,
      myVote: rawVote is Map
          ? MyVoteResponse.fromJson(Map<String, dynamic>.from(rawVote))
          : null,
    );
  }
}

class MyVoteResponse {
  final String? optionId;
  final String? customAnswer;
  final String? reason;
  final DateTime? votedAt;

  const MyVoteResponse({
    this.optionId,
    this.customAnswer,
    this.reason,
    this.votedAt,
  });

  factory MyVoteResponse.fromJson(Map<String, dynamic> json) {
    return MyVoteResponse(
      optionId: json['optionId']?.toString(),
      customAnswer: json['customAnswer'] as String?,
      reason: json['reason'] as String?,
      votedAt: _parseDate(json['votedAt']),
    );
  }
}

class VoteStatsResponse {
  final bool resultsVisible;
  final int minVotesToReveal;
  final int voteProgress;
  final int? totalVotes;
  final int? customAnswerCount;
  final double? customAnswerPercentage;
  final int? whyCount;

  const VoteStatsResponse({
    this.resultsVisible = false,
    this.minVotesToReveal = 0,
    this.voteProgress = 0,
    this.totalVotes,
    this.customAnswerCount,
    this.customAnswerPercentage,
    this.whyCount,
  });

  factory VoteStatsResponse.fromJson(Map<String, dynamic> json) {
    return VoteStatsResponse(
      resultsVisible: json['resultsVisible'] as bool? ?? false,
      minVotesToReveal: _asInt(json['minVotesToReveal']) ?? 0,
      voteProgress: _asInt(json['voteProgress']) ?? 0,
      totalVotes: _asInt(json['totalVotes']),
      customAnswerCount: _asInt(json['customAnswerCount']),
      customAnswerPercentage: _asDouble(json['customAnswerPercentage']),
      whyCount: _asInt(json['whyCount']),
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
