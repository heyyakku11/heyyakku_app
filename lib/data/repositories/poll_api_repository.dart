import 'package:yakku/data/datasources/poll_remote_data_source.dart';
import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/create_poll_option_request.dart';
import 'package:yakku/data/models/poll/create_poll_request.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/data/models/poll/shared_poll_response.dart';

class PollApiRepository {
  PollApiRepository(this._remote);

  final PollRemoteDataSource _remote;

  Future<PollsPage> getPolls({String? cursor}) {
    return _remote.getPolls(cursor: cursor);
  }

  Future<PollResponse> getPollById(String pollId) {
    return _remote.getPollById(pollId);
  }

  Future<SharedPollResponse> getSharedPoll(String shareToken) {
    return _remote.getSharedPoll(shareToken);
  }

  Future<PollResponse> createTextPoll({
    required String question,
    required List<String> options,
    required int selectedOptionIndex,
    Duration? expiresIn,
    bool allowComments = true,
    List<String> categoryIds = const [],
  }) {
    return _remote.createPoll(
      CreatePollRequest(
        question: question,
        optionType: 'text',
        options: options
            .map((text) => CreatePollOptionRequest(text: text))
            .toList(),
        selectedOptionIndex: selectedOptionIndex,
        expiresAt: expiresIn == null
            ? null
            : DateTime.now().toUtc().add(expiresIn),
        allowComments: allowComments,
        categoryIds: categoryIds,
      ),
    );
  }

  Future<CastVoteResponse> castVote({
    required String pollId,
    required String optionId,
  }) {
    return _remote.castVote(
      CastVoteRequest(pollId: pollId, optionId: optionId),
    );
  }
}
