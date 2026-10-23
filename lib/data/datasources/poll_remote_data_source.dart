import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/create_poll_request.dart';
import 'package:yakku/data/models/poll/poll_response.dart';

abstract interface class PollRemoteDataSource {
  Future<PollResponse> getPollById(String pollId);

  Future<PollResponse> getPollByShareCode(String shareCode);

  Future<PollResponse> createPoll(CreatePollRequest request);

  Future<CastVoteResponse> castVote(CastVoteRequest request);
}
