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
    this.question,
    this.selectedOption,
    this.reason,
  });

  final String contentType;
  final String? question;
  final String? selectedOption;
  final String? reason;

  factory AskBackContext.fromJson(Map<String, dynamic> json) {
    return AskBackContext(
      contentType: json['contentType'] as String? ?? 'poll',
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
    required this.isMuted,
    required this.unreadCount,
    required this.canSend,
    required this.canReopen,
    required this.canUnblock,
  });

  final String id;
  final AskBackStatus status;

  /// `asker` (owns the poll or check) or `voter`.
  final String myRole;
  final AskBackParticipant other;
  final AskBackContext context;
  final DateTime createdAt;
  final bool isMuted;
  final int unreadCount;
  final bool canSend;
  final bool canReopen;
  final bool canUnblock;

  bool get isAsker => myRole == 'asker';

  factory AskBackConversation.fromJson(Map<String, dynamic> json) {
    return AskBackConversation(
      id: json['id'] as String,
      status: AskBackStatus.parse(json['status']),
      myRole: json['myRole'] as String? ?? 'voter',
      other: AskBackParticipant.fromJson(_map(json['other'])),
      context: AskBackContext.fromJson(_map(json['context'])),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isMuted: json['isMuted'] as bool? ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      canSend: json['canSend'] as bool? ?? false,
      canReopen: json['canReopen'] as bool? ?? false,
      canUnblock: json['canUnblock'] as bool? ?? false,
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
    required this.isMuted,
  });

  final String id;
  final AskBackStatus status;
  final String myRole;
  final AskBackParticipant other;
  final AskBackPreview? lastMessage;
  final DateTime lastActivityAt;
  final int unreadCount;
  final bool isMuted;

  factory AskBackListItem.fromJson(Map<String, dynamic> json) {
    final last = json['lastMessage'];
    return AskBackListItem(
      id: json['id'] as String,
      status: AskBackStatus.parse(json['status']),
      myRole: json['myRole'] as String? ?? 'voter',
      other: AskBackParticipant.fromJson(_map(json['other'])),
      lastMessage: last is Map
          ? AskBackPreview.fromJson(Map<String, dynamic>.from(last))
          : null,
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }

  AskBackListItem copyWith({
    AskBackStatus? status,
    AskBackPreview? lastMessage,
    DateTime? lastActivityAt,
    int? unreadCount,
    bool? isMuted,
  }) {
    return AskBackListItem(
      id: id,
      status: status ?? this.status,
      myRole: myRole,
      other: other,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
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
