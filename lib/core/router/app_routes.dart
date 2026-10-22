abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const main = '/main';
  static const pollAnswer = '/polls/answer';
  static const pollResults = '/polls/results';

  /// Canonical shared-poll path, identical to the website's `/vote/{shareCode}`.
  static const pollVote = '/vote/:shareCode';
  static String pollVoteLocation(String shareCode) => '/vote/$shareCode';

  static const onboardingName = 'onboarding';
  static const mainName = 'main';
  static const pollAnswerName = 'pollAnswer';
  static const pollResultsName = 'pollResults';
  static const pollVoteName = 'pollVote';
}
