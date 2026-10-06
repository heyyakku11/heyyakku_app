import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/create_poll_request.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/shared_poll_response.dart';

abstract interface class PollRemoteDataSource {
  Future<PollsPage> getPolls({String? cursor});

  Future<PollResponse> getPollById(String pollId);

  Future<SharedPollResponse> getSharedPoll(String shareToken);

  Future<PollResponse> createPoll(CreatePollRequest request);

  Future<CastVoteResponse> castVote(CastVoteRequest request);
}
