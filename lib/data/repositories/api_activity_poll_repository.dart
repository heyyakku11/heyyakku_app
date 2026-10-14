import 'package:yakku/data/datasources/activity_poll_remote_data_source.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll/user_poll_response.dart';
import 'package:yakku/data/models/poll_option.dart';
import 'package:yakku/data/repositories/activity_poll_repository.dart';
import 'package:yakku/domain/enums/poll_answer_type.dart';
import 'package:yakku/domain/enums/poll_options_type.dart';
import 'package:yakku/domain/enums/poll_status.dart';

class ApiActivityPollRepository implements ActivityPollRepository {
  ApiActivityPollRepository(this._remote);

  final ActivityPollRemoteDataSource _remote;

  @override
  Future<List<PollModel>> getCreatedPolls() {
    return _collect(_remote.getAskedPolls);
  }

  @override
  Future<List<PollModel>> getAnsweredPolls() {
    return _collect(_remote.getAnsweredPolls);
  }

  Future<List<PollModel>> _collect(
    Future<UserPollsPage> Function({String? cursor}) fetch,
  ) async {
    final items = <PollModel>[];
    String? cursor;
    final seenCursors = <String>{};

    while (true) {
      final page = await fetch(cursor: cursor);
      items.addAll(page.items.map(_toPollModel));
      final next = page.nextCursor;
      if (!page.hasMore ||
          next == null ||
          next.isEmpty ||
          !seenCursors.add(next)) {
        break;
      }
      cursor = next;
    }

    return List<PollModel>.unmodifiable(items);
  }

  PollModel _toPollModel(UserPollResponse poll) {
    final options = <PollOptionModel>[];
    for (var i = 0; i < poll.pollOptions.length; i++) {
      final option = poll.pollOptions[i];
      options.add(
        PollOptionModel(
          id: option.id,
          type: PollOptionType.text,
          text: option.text,
          sortOrder: i + 1,
          isCustom: false,
        ),
      );
    }

    return PollModel(
      id: poll.pollId,
      question: poll.question,
      answerType: PollAnswerType.singleChoice,
      allowCustomOption: false,
      status: _mapStatus(poll.status),
      options: List<PollOptionModel>.unmodifiable(options),
      totalVoteCount: poll.totalVoteCount,
    );
  }

  PollStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return PollStatus.active;
      default:
        return PollStatus.inactive;
    }
  }
}
