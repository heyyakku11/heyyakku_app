enum PollStatus {
  inactive(0),
  active(1);

  const PollStatus(this.value);

  final int value;

  bool get isActive => this == PollStatus.active;

  static PollStatus fromValue(int value) {
    return PollStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PollStatus.inactive,
    );
  }
}
