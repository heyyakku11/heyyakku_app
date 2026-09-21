import 'package:yakku/data/models/poll/cast_vote_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';

class AnswerPollArgs {
  const AnswerPollArgs({required this.poll});

  final PollResponse poll;
}

class PollResultsArgs {
  const PollResultsArgs({
    required this.poll,
    required this.selectedOptionId,
    required this.vote,
  });

  final PollResponse poll;
  final String selectedOptionId;
  final CastVoteResponse vote;
}
