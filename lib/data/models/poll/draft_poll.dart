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

  DateTime updatedAt = DateTime.fromMillisecondsSinceEpoch(0);

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
