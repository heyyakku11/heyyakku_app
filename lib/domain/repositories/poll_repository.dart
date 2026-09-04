import 'package:yakku/domain/entities/anonymous_user.dart';
import 'package:yakku/domain/entities/poll.dart';
import 'package:yakku/domain/enums/poll_duration.dart';

abstract class PollRepository {
  List<Poll> getFeed({String query = ''});
  List<Poll> getMyPolls();
  Poll? getPoll(String id);
  AnonymousUser getCurrentUser();
  void vote(String pollId, String optionId);
  void voteSomethingElse(String pollId, String optionId, String customText);
  void createPoll({
    required String question,
    required List<String> options,
    required bool isAnonymous,
    required bool allowMultipleAnswers,
    required PollDuration duration,
  });
  void updateProfile({String? displayName});
}
