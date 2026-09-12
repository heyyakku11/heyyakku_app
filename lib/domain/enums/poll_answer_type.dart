enum PollAnswerType {
  singleChoice(1),
  multipleChoice(2);

  const PollAnswerType(this.value);

  final int value;

  static PollAnswerType fromValue(int value) {
    return PollAnswerType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PollAnswerType.singleChoice,
    );
  }
}
