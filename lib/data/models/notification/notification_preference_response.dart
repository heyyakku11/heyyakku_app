class NotificationPreferenceResponse {
  final bool pushEnabled;
  final bool pollActivityEnabled;
  final bool offersEnabled;

  const NotificationPreferenceResponse({
    required this.pushEnabled,
    required this.pollActivityEnabled,
    required this.offersEnabled,
  });

  static const defaults = NotificationPreferenceResponse(
    pushEnabled: true,
    pollActivityEnabled: true,
    offersEnabled: true,
  );

  factory NotificationPreferenceResponse.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceResponse(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      pollActivityEnabled: json['pollActivityEnabled'] as bool? ?? true,
      offersEnabled: json['offersEnabled'] as bool? ?? true,
    );
  }

  NotificationPreferenceResponse copyWith({
    bool? pushEnabled,
    bool? pollActivityEnabled,
    bool? offersEnabled,
  }) {
    return NotificationPreferenceResponse(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      pollActivityEnabled: pollActivityEnabled ?? this.pollActivityEnabled,
      offersEnabled: offersEnabled ?? this.offersEnabled,
    );
  }
}
