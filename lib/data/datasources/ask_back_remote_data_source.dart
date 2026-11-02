import 'package:yakku/data/models/ask_back/ask_back_models.dart';

abstract interface class AskBackRemoteDataSource {
  /// `POST /api/v1/ask-back/conversations`: starts the conversation for a vote
  /// (the reason's id), or returns the existing one. Only the owner of the card
  /// can; the server works out who the other person is.
  Future<AskBackConversation> start(String voteId);

  /// `GET /api/v1/ask-back/conversations`: the signed-in user's conversations,
  /// most recently active first.
  Future<AskBackPage<AskBackListItem>> list({String? cursor});

  Future<AskBackConversation> get(String conversationId);

  /// `GET .../messages`: oldest first within a page. With no [cursor] it is the
  /// newest page; with [newer] it is the messages after [cursor], to catch up
  /// after a reconnect; otherwise the page before [cursor].
  Future<AskBackPage<AskBackMessage>> messages(
    String conversationId, {
    String? cursor,
    bool newer = false,
  });

  /// `POST .../messages`. Sending the same [clientMessageId] again returns the
  /// stored message, so a retry never creates a second one.
  Future<AskBackMessage> send(
    String conversationId, {
    required String clientMessageId,
    required String content,
  });

  Future<AskBackReadResult> markRead(
    String conversationId,
    String lastReadMessageId,
  );

  Future<AskBackConversation> setMuted(String conversationId, bool muted);
  Future<AskBackConversation> close(String conversationId);
  Future<AskBackConversation> reopen(String conversationId);
  Future<AskBackConversation> block(String conversationId, {String? reason});
  Future<AskBackConversation> unblock(String conversationId);
}
