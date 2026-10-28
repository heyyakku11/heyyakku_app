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

  /// The card this notification is about, when the server attached one.
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
      target: NotificationTarget.tryParse(json['data']),
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

/// The poll or check a notification belongs to, read from its `data` JSON
/// (`{ contentId, contentType: "poll" | "check", shareCode }`).
class NotificationTarget {
  const NotificationTarget({required this.contentId, required this.isCheck});

  final String contentId;
  final bool isCheck;

  static NotificationTarget? tryParse(Object? raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return null;
      final id = decoded['contentId']?.toString();
      final type = decoded['contentType']?.toString().toLowerCase();
      if (id == null || id.isEmpty) return null;
      if (type != 'poll' && type != 'check') return null;
      return NotificationTarget(contentId: id, isCheck: type == 'check');
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
