abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const signUp = '/sign-up';
  static const main = '/main';
  static const pollAnswer = '/polls/answer';
  static const pollResults = '/polls/results';

  /// Canonical shared-poll path, identical to the website's `/vote/{shareCode}`.
  static const pollVote = '/vote/:shareCode';
  static String pollVoteLocation(String shareCode) => '/vote/$shareCode';

  /// Ask back: the conversation list, and one private conversation.
  static const askBack = '/ask-back';
  static const askBackChat = '/ask-back/:conversationId';
  static String askBackChatLocation(String conversationId) =>
      '/ask-back/$conversationId';

  static const onboardingName = 'onboarding';
  static const signUpName = 'signUp';
  static const askBackName = 'askBack';
  static const askBackChatName = 'askBackChat';
  static const mainName = 'main';
  static const pollAnswerName = 'pollAnswer';
  static const pollResultsName = 'pollResults';
  static const pollVoteName = 'pollVote';
}
