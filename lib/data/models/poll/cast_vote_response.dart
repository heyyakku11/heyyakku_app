import 'package:yakku/data/models/poll/shared_content_response.dart';

/// The caller's vote, derived from the `POST /api/v1/votes` response (the
/// content as the voter now sees it).
class CastVoteResponse {
  final String id;
  final String pollId;
  final String? pollOptionId;
  final String? customAnswer;
  final String? reason;
  final DateTime createdAt;

  const CastVoteResponse({
    required this.id,
    required this.pollId,
    required this.createdAt,
    this.pollOptionId,
    this.customAnswer,
    this.reason,
  });

  factory CastVoteResponse.fromShared(SharedContentResponse content) {
    final vote = content.voting.myVote;
    return CastVoteResponse(
      id: content.contentId,
      pollId: content.contentId,
      pollOptionId: vote?.optionId,
      customAnswer: vote?.customAnswer,
      reason: vote?.reason,
      createdAt: vote?.votedAt ?? DateTime.now().toUtc(),
    );
  }
}
