import 'package:yakku/data/datasources/poll_remote_data_source.dart';
import 'package:yakku/data/models/poll/cast_vote_request.dart';
import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/create_poll_option_request.dart';
import 'package:yakku/data/models/poll/create_poll_request.dart';
import 'package:yakku/data/models/poll/poll_response.dart';

class PollApiRepository {
  PollApiRepository(this._remote);

  final PollRemoteDataSource _remote;

  Future<PollResponse> getPollById(String pollId) {
    return _remote.getPollById(pollId);
  }

  Future<PollResponse> getPollByShareCode(String shareCode) {
    return _remote.getPollByShareCode(shareCode);
  }

  Future<PollResponse> createTextPoll({
    required String question,
    required List<String> options,
    required int selectedOptionIndex,
  }) {
    return _createPoll(
      question: question,
      options: options,
      selectedOptionIndex: selectedOptionIndex,
      contentType: 'question',
    );
  }

  Future<PollResponse> createImagePoll({
    required String question,
    required List<String> options,
    required int selectedOptionIndex,
    required String mediaUploadSessionId,
  }) {
    return _createPoll(
      question: question,
      options: options,
      selectedOptionIndex: selectedOptionIndex,
      contentType: 'image',
      mediaUploadSessionId: mediaUploadSessionId,
    );
  }

  Future<PollResponse> _createPoll({
    required String question,
    required List<String> options,
    required int selectedOptionIndex,
    required String contentType,
    String? mediaUploadSessionId,
  }) async {
    if (selectedOptionIndex < 0 || selectedOptionIndex >= options.length) {
      throw ArgumentError.value(
        selectedOptionIndex,
        'selectedOptionIndex',
        'Must point at an option',
      );
    }

    final poll = await _remote.createPoll(
      CreatePollRequest(
        question: question,
        contentType: contentType,
        mediaUploadSessionId: mediaUploadSessionId,
        options: [
          for (var i = 0; i < options.length; i++)
            CreatePollOptionRequest(text: options[i], displayOrder: i + 1),
        ],
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 24)),
      ),
    );

    final sortedOptions = [...poll.options]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (selectedOptionIndex < sortedOptions.length) {
      await _remote.castVote(
        CastVoteRequest(
          shareCode: poll.shareCode,
          optionId: sortedOptions[selectedOptionIndex].id,
        ),
      );
    }

    return poll;
  }

  Future<CastVoteResponse> castVote({
    required String shareCode,
    required String optionId,
  }) {
    return _remote.castVote(
      CastVoteRequest(shareCode: shareCode, optionId: optionId),
    );
  }
}
