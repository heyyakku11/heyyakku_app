enum PollOptionType {
  text(1),
  image(2),
  unknown(-1);

  const PollOptionType(this.value);

  final int value;

  static PollOptionType fromValue(int value) {
    return PollOptionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PollOptionType.unknown,
    );
  }
}
