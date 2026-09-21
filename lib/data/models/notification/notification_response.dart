class NotificationResponse {
  final String id;
  final String type;
  final String eventType;
  final String title;
  final String body;
  final String? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const NotificationResponse({
    required this.id,
    required this.type,
    required this.eventType,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.data,
    this.readAt,
    this.expiresAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      readAt: _parseDate(json['readAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      expiresAt: _parseDate(json['expiresAt']),
    );
  }
}

class NotificationsPage {
  final List<NotificationResponse> items;
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
