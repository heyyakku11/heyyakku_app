/// Ask Back models. They carry only what the API returns: an anonymous name per
/// person and ids of conversations and messages, never a user id.
library;

enum AskBackStatus {
  active,
  closed,
  blocked;

  static AskBackStatus parse(Object? value) {
    return switch (value) {
      'closed' => AskBackStatus.closed,
      'blocked' => AskBackStatus.blocked,
      _ => AskBackStatus.active,
    };
  }
}

/// Whose turn it is in a conversation, as the signed-in user sees it: the asker
/// sends first, the voter replies once, then the asker again; [done] when every
/// allowed question has been answered.
enum AskBackTurn {
  me,
  them,
  done;

  static AskBackTurn parse(Object? value) {
    return switch (value) {
      'me' => AskBackTurn.me,
      'done' => AskBackTurn.done,
      _ => AskBackTurn.them,
    };
  }
}

class AskBackParticipant {
  const AskBackParticipant({
    required this.anonymousName,
    this.isDeleted = false,
  });

  final String anonymousName;
  final bool isDeleted;

  factory AskBackParticipant.fromJson(Map<String, dynamic> json) {
    return AskBackParticipant(
      anonymousName: json['anonymousName'] as String? ?? 'Someone',
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}

/// What the conversation is about, read live from the vote.
class AskBackContext {
  const AskBackContext({
    required this.contentType,
    this.contentId,
    this.title,
    this.question,
    this.selectedOption,
    this.reason,
  });

  final String contentType;

  /// Poll or made-check id; used to unlock the card from chat.
  final String? contentId;

  /// Short list tag: a check's title, or "Question" for a poll.
  final String? title;
  final String? question;
  final String? selectedOption;
  final String? reason;

  factory AskBackContext.fromJson(Map<String, dynamic> json) {
    return AskBackContext(
      contentType: json['contentType'] as String? ?? 'poll',
      contentId: json['contentId']?.toString(),
      title: json['title'] as String?,
      question: json['question'] as String?,
      selectedOption: json['selectedOption'] as String?,
      reason: json['reason'] as String?,
    );
  }
}

class AskBackConversation {
  const AskBackConversation({
    required this.id,
    required this.status,
    required this.myRole,
    required this.other,
    required this.context,
    required this.createdAt,
    required this.unreadCount,
    required this.canSend,
    required this.canReopen,
    required this.canUnblock,
    this.turn = AskBackTurn.them,
    this.messagesLeft,
    this.isPaused = false,
    this.waitingReplies,
  });

  final String id;
  final AskBackStatus status;

  /// `asker` (owns the poll or check) or `voter`.
  final String myRole;
  final AskBackParticipant other;
  final AskBackContext context;
  final DateTime createdAt;
  final int unreadCount;

  /// Active, not paused and my turn.
  final bool canSend;
  final bool canReopen;

  /// True only for the person who blocked, so only they see "blocked".
  final bool canUnblock;
  final AskBackTurn turn;

  /// Messages I can still send; null when there is no limit.
  final int? messagesLeft;

  /// Read-only for both people because the asker's plan expired.
  final bool isPaused;

  /// Reasons still on the card; set when the free ask back is used up.
  final int? waitingReplies;

  bool get isAsker => myRole == 'asker';

  factory AskBackConversation.fromJson(Map<String, dynamic> json) {
    return AskBackConversation(
      id: json['id'] as String,
      status: AskBackStatus.parse(json['status']),
      myRole: json['myRole'] as String? ?? 'voter',
      other: AskBackParticipant.fromJson(_map(json['other'])),
      context: AskBackContext.fromJson(_map(json['context'])),
      createdAt: DateTime.parse(json['createdAt'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      canSend: json['canSend'] as bool? ?? false,
      canReopen: json['canReopen'] as bool? ?? false,
      canUnblock: json['canUnblock'] as bool? ?? false,
      turn: AskBackTurn.parse(json['turn']),
      messagesLeft: (json['messagesLeft'] as num?)?.toInt(),
      isPaused: json['isPaused'] as bool? ?? false,
      waitingReplies: (json['waitingReplies'] as num?)?.toInt(),
    );
  }
}

/// What the owner can do with Ask Back on one card: `GET /ask-back/access` and
/// the answer of `POST /ask-back/unlocks`.
class AskBackAccess {
  const AskBackAccess({
    required this.unlocked,
    required this.paused,
    required this.planCode,
    required this.planName,
    required this.planExpired,
    required this.canUnlock,
    this.reasonsRevealed = true,
    this.unlockSource,
    this.planExpiresAt,
    this.ticketsLeft,
    this.messageLimit,
    this.unlimitedMessages = false,
  });

  /// Every reason on the card can be asked back.
  final bool unlocked;

  /// The owner can read every reason on the card (bought on its own, or an
  /// active paid plan). False on the free plan, where only each option's top
  /// reason is readable. Defaults to true for an older server.
  final bool reasonsRevealed;

  /// `plan` or `purchase` when unlocked.
  final String? unlockSource;

  /// Unlocked through a plan that has expired: chats are read-only.
  final bool paused;
  final String planCode;
  final String planName;
  final DateTime? planExpiresAt;

  /// A paid plan was bought and has ended.
  final bool planExpired;

  /// Tickets left; null when there is no ticket limit or no active plan.
  final int? ticketsLeft;

  /// The active plan can unlock this card now.
  final bool canUnlock;

  /// Questions per reason; null with [unlimitedMessages] means no limit.
  final int? messageLimit;
  final bool unlimitedMessages;

  bool get isFreePlan => planCode == 'free';

  factory AskBackAccess.fromJson(Map<String, dynamic> json) {
    final expires = json['planExpiresAt'];
    return AskBackAccess(
      unlocked: json['unlocked'] as bool? ?? false,
      reasonsRevealed: json['reasonsRevealed'] as bool? ?? true,
      unlockSource: json['unlockSource'] as String?,
      paused: json['paused'] as bool? ?? false,
      planCode: json['planCode'] as String? ?? 'free',
      planName: json['planName'] as String? ?? 'Free',
      planExpiresAt: expires is String ? DateTime.tryParse(expires) : null,
      planExpired: json['planExpired'] as bool? ?? false,
      ticketsLeft: (json['ticketsLeft'] as num?)?.toInt(),
      canUnlock: json['canUnlock'] as bool? ?? false,
      messageLimit: (json['messageLimit'] as num?)?.toInt(),
      unlimitedMessages: json['unlimitedMessages'] as bool? ?? false,
    );
  }
}

class AskBackPreview {
  const AskBackPreview({
    required this.preview,
    required this.isMine,
    required this.createdAt,
  });

  final String preview;
  final bool isMine;
  final DateTime createdAt;

  factory AskBackPreview.fromJson(Map<String, dynamic> json) {
    return AskBackPreview(
      preview: json['preview'] as String? ?? '',
      isMine: json['isMine'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AskBackListItem {
  const AskBackListItem({
    required this.id,
    required this.status,
    required this.myRole,
    required this.other,
    required this.lastMessage,
    required this.lastActivityAt,
    required this.unreadCount,
    this.context = const AskBackContext(contentType: 'poll'),
    this.turn = AskBackTurn.them,
    this.canSend = false,
    this.isPaused = false,
    this.messagesLeft,
  });

  final String id;
  final AskBackStatus status;
  final String myRole;
  final AskBackParticipant other;
  final AskBackContext context;
  final AskBackPreview? lastMessage;
  final DateTime lastActivityAt;
  final int unreadCount;
  final AskBackTurn turn;
  final bool canSend;
  final bool isPaused;
  final int? messagesLeft;

  bool get isAsker => myRole == 'asker';

  /// Closed, blocked, finished, or paused: the Ended tab.
  bool get isEnded =>
      status != AskBackStatus.active || turn == AskBackTurn.done || isPaused;

  /// Active and my turn to write.
  bool get isYourTurn => !isEnded && turn == AskBackTurn.me;

  /// Active and waiting for the other person.
  bool get isWaiting => !isEnded && turn == AskBackTurn.them;

  factory AskBackListItem.fromJson(Map<String, dynamic> json) {
    final last = json['lastMessage'];
    return AskBackListItem(
      id: json['id'] as String,
      status: AskBackStatus.parse(json['status']),
      myRole: json['myRole'] as String? ?? 'voter',
      other: AskBackParticipant.fromJson(_map(json['other'])),
      context: AskBackContext.fromJson(_map(json['context'])),
      lastMessage: last is Map
          ? AskBackPreview.fromJson(Map<String, dynamic>.from(last))
          : null,
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      turn: AskBackTurn.parse(json['turn']),
      canSend: json['canSend'] as bool? ?? false,
      isPaused: json['isPaused'] as bool? ?? false,
      messagesLeft: (json['messagesLeft'] as num?)?.toInt(),
    );
  }

  AskBackListItem copyWith({
    AskBackStatus? status,
    AskBackPreview? lastMessage,
    DateTime? lastActivityAt,
    int? unreadCount,
    AskBackTurn? turn,
    bool? canSend,
    bool? isPaused,
    AskBackContext? context,
  }) {
    return AskBackListItem(
      id: id,
      status: status ?? this.status,
      myRole: myRole,
      other: other,
      context: context ?? this.context,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      unreadCount: unreadCount ?? this.unreadCount,
      turn: turn ?? this.turn,
      canSend: canSend ?? this.canSend,
      isPaused: isPaused ?? this.isPaused,
      messagesLeft: messagesLeft,
    );
  }
}

/// A message as the server returns it. [cursor] is the position to page from.
class AskBackMessage {
  const AskBackMessage({
    required this.id,
    required this.conversationId,
    required this.clientMessageId,
    required this.content,
    required this.senderName,
    required this.isMine,
    required this.createdAt,
    required this.cursor,
  });

  final String id;
  final String conversationId;
  final String clientMessageId;
  final String content;
  final String senderName;
  final bool isMine;
  final DateTime createdAt;
  final String cursor;

  factory AskBackMessage.fromJson(Map<String, dynamic> json) {
    return AskBackMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      clientMessageId: json['clientMessageId'] as String,
      content: json['content'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      isMine: json['isMine'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cursor: json['cursor'] as String? ?? '',
    );
  }
}

class AskBackPage<T> {
  const AskBackPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}

class AskBackReadResult {
  const AskBackReadResult({required this.advanced, required this.unreadCount});

  final bool advanced;
  final int unreadCount;
}

/// `MessageRead`: the other person read up to [lastReadMessageId].
class AskBackReadEvent {
  const AskBackReadEvent({
    required this.conversationId,
    required this.lastReadMessageId,
  });

  final String conversationId;
  final String lastReadMessageId;
}

/// `ConversationClosed` (closed or blocked) and `ConversationReopened`.
class AskBackStatusEvent {
  const AskBackStatusEvent({
    required this.conversationId,
    required this.status,
  });

  final String conversationId;
  final AskBackStatus status;
}

Map<String, dynamic> _map(Object? value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}
