import 'package:yakku/data/models/Poll.dart';
import 'package:yakku/data/models/poll_option.dart';
import 'package:yakku/domain/enums/poll_answer_type.dart';
import 'package:yakku/domain/enums/poll_options_type.dart';
import 'package:yakku/domain/enums/poll_status.dart';

/// Dummy created/answered polls until the real activity API is wired up.
class ActivityPollDataSource {
  const ActivityPollDataSource();

  List<PollModel> fetchCreatedPolls() => List<PollModel>.unmodifiable(_created);

  List<PollModel> fetchAnsweredPolls() =>
      List<PollModel>.unmodifiable(_answered);
}

PollOptionModel _textOption({
  required String id,
  required String text,
  required int sortOrder,
  bool isCustom = false,
}) {
  return PollOptionModel(
    id: id,
    type: PollOptionType.text,
    text: text,
    sortOrder: sortOrder,
    isCustom: isCustom,
  );
}

PollOptionModel _imageOption({
  required String id,
  required String imageUrl,
  required int sortOrder,
}) {
  return PollOptionModel(
    id: id,
    type: PollOptionType.image,
    imageUrl: imageUrl,
    sortOrder: sortOrder,
    isCustom: false,
  );
}

final List<PollModel> _created = [
  PollModel(
    id: 'created_poll_1',
    question: 'Should I text them again?',
    categoryId: 'category_relationships',
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: true,
    status: PollStatus.active,
    options: [
      _textOption(id: 'created_1_opt_1', text: 'Text them', sortOrder: 1),
      _textOption(id: 'created_1_opt_2', text: "Don't text them", sortOrder: 2),
      _textOption(
        id: 'created_1_opt_3',
        text: 'Wait for them to text first',
        sortOrder: 3,
      ),
    ],
  ),
  PollModel(
    id: 'created_poll_2',
    question: 'Which outfit should I wear tonight?',
    categoryId: 'category_fashion',
    answerType: PollAnswerType.multipleChoice,
    allowCustomOption: true,
    status: PollStatus.active,
    options: [
      _textOption(id: 'created_2_opt_1', text: 'Black shirt', sortOrder: 1),
      _textOption(id: 'created_2_opt_2', text: 'White shirt', sortOrder: 2),
      _textOption(id: 'created_2_opt_3', text: 'Blue shirt', sortOrder: 3),
    ],
  ),
  PollModel(
    id: 'created_poll_3',
    question: 'Which profile picture should I use?',
    categoryId: 'category_profile',
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: true,
    status: PollStatus.active,
    options: [
      _imageOption(
        id: 'created_3_opt_1',
        imageUrl: 'https://picsum.photos/seed/yakku-profile-1/400/400',
        sortOrder: 1,
      ),
      _imageOption(
        id: 'created_3_opt_2',
        imageUrl: 'https://picsum.photos/seed/yakku-profile-2/400/400',
        sortOrder: 2,
      ),
      _imageOption(
        id: 'created_3_opt_3',
        imageUrl: 'https://picsum.photos/seed/yakku-profile-3/400/400',
        sortOrder: 3,
      ),
    ],
  ),
  PollModel(
    id: 'created_poll_4',
    question: 'Should I buy this phone?',
    categoryId: null,
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: true,
    status: PollStatus.active,
    options: [
      _textOption(id: 'created_4_opt_1', text: 'Buy it', sortOrder: 1),
      _textOption(id: 'created_4_opt_2', text: 'Wait for a sale', sortOrder: 2),
      _textOption(
        id: 'created_4_opt_3',
        text: 'Look at other models',
        sortOrder: 3,
      ),
    ],
  ),
  PollModel(
    id: 'created_poll_5',
    question: 'Where should I go this weekend?',
    categoryId: 'category_travel',
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: true,
    status: PollStatus.active,
    options: [
      _textOption(id: 'created_5_opt_1', text: 'Beach', sortOrder: 1),
      _textOption(id: 'created_5_opt_2', text: 'Mountains', sortOrder: 2),
      _textOption(id: 'created_5_opt_3', text: 'Stay home', sortOrder: 3),
    ],
  ),
];

final List<PollModel> _answered = [
  PollModel(
    id: 'answered_poll_1',
    question: 'Should I accept this job offer?',
    categoryId: 'category_career',
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: true,
    status: PollStatus.active,
    options: [
      _textOption(id: 'answered_1_opt_1', text: 'Accept it', sortOrder: 1),
      _textOption(id: 'answered_1_opt_2', text: 'Reject it', sortOrder: 2),
      _textOption(
        id: 'answered_1_opt_3',
        text: 'Ask for more time',
        sortOrder: 3,
      ),
    ],
  ),
  PollModel(
    id: 'answered_poll_2',
    question: 'Where should we go for dinner?',
    categoryId: 'category_food',
    answerType: PollAnswerType.multipleChoice,
    allowCustomOption: true,
    status: PollStatus.active,
    options: [
      _textOption(id: 'answered_2_opt_1', text: 'Pizza', sortOrder: 1),
      _textOption(id: 'answered_2_opt_2', text: 'Burgers', sortOrder: 2),
      _textOption(id: 'answered_2_opt_3', text: 'Indian', sortOrder: 3),
    ],
  ),
  PollModel(
    id: 'answered_poll_3',
    question: 'Which vacation destination should we choose?',
    categoryId: 'category_travel',
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: true,
    status: PollStatus.active,
    options: [
      _imageOption(
        id: 'answered_3_opt_1',
        imageUrl: 'https://picsum.photos/seed/yakku-vacation-1/400/400',
        sortOrder: 1,
      ),
      _imageOption(
        id: 'answered_3_opt_2',
        imageUrl: 'https://picsum.photos/seed/yakku-vacation-2/400/400',
        sortOrder: 2,
      ),
      _imageOption(
        id: 'answered_3_opt_3',
        imageUrl: 'https://picsum.photos/seed/yakku-vacation-3/400/400',
        sortOrder: 3,
      ),
    ],
  ),
  PollModel(
    id: 'answered_poll_4',
    question: 'Should I start going to the gym?',
    categoryId: 'category_health',
    answerType: PollAnswerType.singleChoice,
    allowCustomOption: true,
    status: PollStatus.active,
    options: [
      _textOption(
        id: 'answered_4_opt_1',
        text: 'Start this week',
        sortOrder: 1,
      ),
      _textOption(
        id: 'answered_4_opt_2',
        text: 'Start next month',
        sortOrder: 2,
      ),
      _textOption(id: 'answered_4_opt_3', text: 'Not right now', sortOrder: 3),
    ],
  ),
  PollModel(
    id: 'answered_poll_5',
    question: 'Which movie should we watch tonight?',
    categoryId: 'category_entertainment',
    answerType: PollAnswerType.multipleChoice,
    allowCustomOption: true,
    status: PollStatus.active,
    options: [
      _textOption(id: 'answered_5_opt_1', text: 'Comedy', sortOrder: 1),
      _textOption(id: 'answered_5_opt_2', text: 'Action', sortOrder: 2),
      _textOption(id: 'answered_5_opt_3', text: 'Thriller', sortOrder: 3),
    ],
  ),
];
