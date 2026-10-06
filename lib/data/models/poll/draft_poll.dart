import 'package:isar_community/isar.dart';
import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll_option.dart';
import 'package:yakku/domain/enums/poll_answer_type.dart';
import 'package:yakku/domain/enums/poll_options_type.dart';
import 'package:yakku/domain/enums/poll_status.dart';

part 'draft_poll.g.dart';

@collection
class DraftPoll {
  Id id = Isar.autoIncrement;

  String question = '';

  List<String> options = [];

  int expiryDays = 1;

  bool allowComments = true;

  List<String> categoryIds = [];

  DateTime updatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  DraftPoll();

  factory DraftPoll.fromPollModel(PollModel poll) {
    final categoryId = poll.categoryId?.trim() ?? '';
    return DraftPoll()
      ..question = poll.question
      ..options = poll.standardOptions
          .map((option) => option.text?.trim() ?? '')
          .where((text) => text.isNotEmpty)
          .toList(growable: false)
      ..allowComments = true
      ..expiryDays = 0
      ..categoryIds = [if (categoryId.isNotEmpty) categoryId];
  }

  PollModel toPollModel() {
    final trimmedQuestion = question.trim();
    final texts = options
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList(growable: false);

    return PollModel(
      id: id.toString(),
      question: trimmedQuestion.isEmpty ? 'Untitled draft' : trimmedQuestion,
      answerType: PollAnswerType.singleChoice,
      allowCustomOption: false,
      status: PollStatus.inactive,
      options: [
        for (var i = 0; i < texts.length; i++)
          PollOptionModel(
            id: '$id-option-$i',
            type: PollOptionType.text,
            text: texts[i],
            sortOrder: i,
            isCustom: false,
          ),
      ],
    );
  }
}
