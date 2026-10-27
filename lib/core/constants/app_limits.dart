abstract final class AppLimits {
  /// User-generated options only. Something else is extra and mandatory.
  static const int minOptions = 2;
  static const int maxOptions = 3;
  static const int maxQuestionLength = 120;
  static const int maxOptionLength = 40;

  /// Fallback for votes needed before results are revealed; the API sends
  /// the real value as `minVotes`.

  static const int minVotesToReveal = 1;
  static const String somethingElseHint = 'something else';
  static const String somethingElseLabel = 'Something else';
}
