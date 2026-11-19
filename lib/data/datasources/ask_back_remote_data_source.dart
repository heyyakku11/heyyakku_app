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

  Future<AskBackConversation> reopen(String conversationId);

  /// Blocks the other person. The server always files a report ([reason] is
  /// the label the user picked) and ends the chat; blocking also stops that
  /// person from voting on the user's cards or asking them back.
  Future<AskBackConversation> block(String conversationId, {String? reason});

  /// `GET /api/v1/ask-back/access`: whether the card of [voteId] is unlocked,
  /// how, and what the user's plan allows.
  Future<AskBackAccess> getAccess(String voteId);

  /// `GET /api/v1/ask-back/card-access`: the same as [getAccess] for the card
  /// itself ([contentType] is `poll` or `check`, [contentId] the poll id or the
  /// made check's id). `reasonsRevealed` false means the free plan: reasons
  /// other than each option's top one are hidden.
  Future<AskBackAccess> getCardAccess(String contentType, String contentId);

  /// `POST /api/v1/ask-back/unlocks`: unlocks the card of [voteId] with a plan
  /// ticket. Fails with a 403 `ASK_BACK_UNLOCK_REQUIRED` when there is no plan
  /// or no ticket left.
  Future<AskBackAccess> unlock(String voteId);
}
