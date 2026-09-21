import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/create_poll_request.dart';
import 'package:yakku/data/models/poll/poll_response.dart';

abstract interface class PollRemoteDataSource {
  Future<PollResponse> createPoll(CreatePollRequest request);

  Future<CastVoteResponse> castVote({
    required String pollId,
    required CastVoteRequest request,
  });
}
