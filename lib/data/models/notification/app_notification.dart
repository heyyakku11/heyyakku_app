import 'dart:convert';

/// One in-app notification from `GET /api/v1/notifications`.
class AppNotification {
  final String id;
  final String type;
  final String eventType;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  /// Where the client should navigate when the row is opened.
  final NotificationTarget? target;

  const AppNotification({
    required this.id,
    required this.type,
    required this.eventType,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.target,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      target:
          NotificationTarget.tryParse(json['target']) ??
          NotificationTarget.tryParse(json['data']),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      eventType: eventType,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      target: target,
    );
  }
}

/// Navigation payload for a notification.
///
/// Prefers the structured `target` object from the API
/// (`screen`, `conversationId`, `contentType`, `contentId`). Falls back to
/// decoding the legacy `data` JSON blob.
class NotificationTarget {
  const NotificationTarget({
    this.screen,
    this.conversationId,
    this.contentId,
    this.isCheck = false,
    this.isPersonality = false,
  });

  /// askBackConversation | cardResults | cardResultsReady | personalityReady |
  /// personalityResults (legacy ready) | cardShare
  final String? screen;
  final String? conversationId;
  final String? contentId;
  final bool isCheck;
  final bool isPersonality;

  bool get isAskBackConversation {
    if (screen == 'askBackConversation') return true;
    return conversationId != null && conversationId!.isNotEmpty;
  }

  /// Ordinary personality vote / progress (not the ready celebration).
  bool get isPersonalityProgress {
    if (!isPersonality) return false;
    if (isPersonalityReady || isCardShare) return false;
    return true;
  }

  /// "Who you are is in" / results-ready celebration (push-only entry).
  /// Accepts legacy `personalityResults` from older payloads.
  bool get isPersonalityReady {
    if (!isPersonality) return false;
    return screen == 'personalityReady' || screen == 'personalityResults';
  }

  /// Poll/check results-ready celebration (push-only entry).
  bool get isCardResultsReady => screen == 'cardResultsReady';

  /// Nudge to share the card again (not a vote result tap).
  bool get isCardShare => screen == 'cardShare';

  static NotificationTarget? tryParse(Object? raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);

      final screen = map['screen']?.toString();
      final conversationId = map['conversationId']?.toString();
      final contentId = map['contentId']?.toString();
      final type = map['contentType']?.toString().toLowerCase();

      final hasConversation =
          conversationId != null && conversationId.isNotEmpty;
      final isAskBack =
          screen == 'askBackConversation' ||
          (hasConversation &&
              (screen == null || screen == 'askBackConversation'));

      if (isAskBack && hasConversation) {
        return NotificationTarget(
          screen: screen ?? 'askBackConversation',
          conversationId: conversationId,
          contentId: contentId,
          isCheck: type == 'check',
        );
      }

      if (type == 'personality' ||
          screen == 'personalityReady' ||
          screen == 'personalityResults') {
        if (contentId == null || contentId.isEmpty) return null;
        // Old pushes omit `screen`; treat them as ordinary vote/progress.
        return NotificationTarget(
          screen: screen ?? 'cardResults',
          contentId: contentId,
          isPersonality: true,
        );
      }

      if (contentId == null || contentId.isEmpty) return null;
      if (type != null && type != 'poll' && type != 'check') return null;

      return NotificationTarget(
        screen: screen,
        contentId: contentId,
        isCheck: type == 'check',
      );
    } catch (_) {
      return null;
    }
  }
}

class NotificationsPage {
  final List<AppNotification> items;
  final String? nextCursor;
  final bool hasMore;

  const NotificationsPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
