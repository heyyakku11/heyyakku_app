import 'package:yakku/data/models/poll/poll_option_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/poll_why.dart';

class UserPollDetailOptionResponse {
  final String id;
  final String? text;
  final int sortOrder;
  final int voteCount;
  final double percentage;

  const UserPollDetailOptionResponse({
    required this.id,
    required this.sortOrder,
    required this.voteCount,
    required this.percentage,
    this.text,
  });

  factory UserPollDetailOptionResponse.fromJson(Map<String, dynamic> json) {
    return UserPollDetailOptionResponse(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String?,
      sortOrder: _asInt(json['sortOrder']),
      voteCount: _asInt(json['voteCount']),
      percentage: _asDouble(json['percentage']),
    );
  }
}

class YouVsCrowdResponse {
  final String? yourOptionId;
  final String? yourOptionText;
  final double? yourOptionPercentage;
  final String? crowdLeadingOptionId;
  final String? crowdLeadingOptionText;
  final double? crowdLeadingPercentage;
  final bool? agreesWithCrowd;

  const YouVsCrowdResponse({
    this.yourOptionId,
    this.yourOptionText,
    this.yourOptionPercentage,
    this.crowdLeadingOptionId,
    this.crowdLeadingOptionText,
    this.crowdLeadingPercentage,
    this.agreesWithCrowd,
  });

  factory YouVsCrowdResponse.fromJson(Map<String, dynamic> json) {
    return YouVsCrowdResponse(
      yourOptionId: json['yourOptionId']?.toString(),
      yourOptionText: json['yourOptionText'] as String?,
      yourOptionPercentage: _asNullableDouble(json['yourOptionPercentage']),
      crowdLeadingOptionId: json['crowdLeadingOptionId']?.toString(),
      crowdLeadingOptionText: json['crowdLeadingOptionText'] as String?,
      crowdLeadingPercentage: _asNullableDouble(json['crowdLeadingPercentage']),
      agreesWithCrowd: json['agreesWithCrowd'] as bool?,
    );
  }
}

class UserPollDetailResponse {
  final String pollId;
  final String shareCode;
  final String question;
  final String contentType;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final int totalVoteCount;
  final int minVotes;
  final int voteProgress;
  final bool resultsUnlocked;
  final int customAnswerCount;
  final int totalWhyCount;
  final List<UserPollDetailOptionResponse> pollOptions;
  final YouVsCrowdResponse youVsCrowd;

  /// Client-only preview data (not returned by the API).
  final List<PollWhy> whys;

  const UserPollDetailResponse({
    required this.pollId,
    required this.question,
    required this.contentType,
    required this.status,
    required this.createdAt,
    required this.totalVoteCount,
    required this.pollOptions,
    required this.youVsCrowd,
    this.shareCode = '',
    this.minVotes = 0,
    this.voteProgress = 0,
    this.resultsUnlocked = false,
    this.expiresAt,
    this.customAnswerCount = 0,
    this.totalWhyCount = 0,
    this.whys = const [],
  });

  factory UserPollDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['pollOptions'] as List<dynamic>? ?? const [];
    final rawYouVsCrowd = json['youVsCrowd'];
    return UserPollDetailResponse(
      pollId: json['pollId']?.toString() ?? '',
      shareCode: json['shareCode'] as String? ?? '',
      question: json['question'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'question',
      status: json['status'] as String? ?? '',
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      totalVoteCount: _asInt(json['totalVoteCount']),
      minVotes: _asInt(json['minVotes']),
      voteProgress: _asInt(json['voteProgress']),
      resultsUnlocked: json['resultsUnlocked'] as bool? ?? false,
      customAnswerCount: _asInt(json['customAnswerCount']),
      totalWhyCount: _asInt(json['totalWhyCount']),
      pollOptions: rawOptions
          .whereType<Map>()
          .map(
            (item) => UserPollDetailOptionResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      youVsCrowd: rawYouVsCrowd is Map
          ? YouVsCrowdResponse.fromJson(
              Map<String, dynamic>.from(rawYouVsCrowd),
            )
          : const YouVsCrowdResponse(),
    );
  }

  /// Adapts the owner's detail view to the poll model the results screen uses.
  PollResponse toPollResponse() {
    return PollResponse(
      id: pollId,
      shareCode: shareCode,
      question: question,
      contentType: contentType,
      status: status,
      visibility: '',
      expiresAt: expiresAt,
      createdAt: createdAt,
      totalVoteCount: totalVoteCount,
      customAnswerCount: customAnswerCount,
      totalWhyCount: totalWhyCount,
      minVotes: minVotes,
      voteProgress: voteProgress,
      resultsUnlocked: resultsUnlocked,
      options: [
        for (final option in pollOptions)
          PollOptionResponse(
            id: option.id,
            text: option.text,
            sortOrder: option.sortOrder,
            voteCount: option.voteCount,
            percentage: option.percentage,
          ),
      ],
    );
  }
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

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
