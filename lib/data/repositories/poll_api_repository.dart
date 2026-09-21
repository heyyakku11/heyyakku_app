import 'package:yakku/data/datasources/poll_remote_data_source.dart';
import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/create_poll_option_request.dart';
import 'package:yakku/data/models/poll/create_poll_request.dart';
import 'package:yakku/data/models/poll/poll_response.dart';

class PollApiRepository {
  PollApiRepository(this._remote);

  final PollRemoteDataSource _remote;

  Future<PollResponse> createTextPoll({
    required String question,
    required List<String> options,
    required int selectedOptionIndex,
    Duration expiresIn = const Duration(hours: 24),
  }) {
    return _remote.createPoll(
      CreatePollRequest(
        question: question,
        optionType: 'text',
        options: options
            .map((text) => CreatePollOptionRequest(text: text))
            .toList(),
        selectedOptionIndex: selectedOptionIndex,
        expiresAt: DateTime.now().toUtc().add(expiresIn),
      ),
    );
  }

  Future<CastVoteResponse> castVote({
    required String pollId,
    required String optionId,
  }) {
    return _remote.castVote(
      pollId: pollId,
      request: CastVoteRequest(optionId: optionId),
    );
  }
}
