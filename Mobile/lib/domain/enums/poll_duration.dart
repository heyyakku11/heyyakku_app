enum PollDuration {
  hours24,
  days3,
  week1;

  Duration get duration {
    switch (this) {
      case PollDuration.hours24:
        return const Duration(hours: 24);
      case PollDuration.days3:
        return const Duration(days: 3);
      case PollDuration.week1:
        return const Duration(days: 7);
    }
  }

  String get label {
    switch (this) {
      case PollDuration.hours24:
        return '24 hours';
      case PollDuration.days3:
        return '3 days';
      case PollDuration.week1:
        return '1 week';
    }
  }
}
