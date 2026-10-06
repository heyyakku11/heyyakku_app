class NotificationPreferenceResponse {
  final bool pushEnabled;
  final bool pollActivityEnabled;
  final bool offersEnabled;
  final bool alertsEnabled;
  final bool normalEnabled;

  const NotificationPreferenceResponse({
    required this.pushEnabled,
    required this.pollActivityEnabled,
    required this.offersEnabled,
    required this.alertsEnabled,
    required this.normalEnabled,
  });

  factory NotificationPreferenceResponse.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceResponse(
      pushEnabled: json['pushEnabled'] as bool? ?? false,
      pollActivityEnabled: json['pollActivityEnabled'] as bool? ?? false,
      offersEnabled: json['offersEnabled'] as bool? ?? false,
      alertsEnabled: json['alertsEnabled'] as bool? ?? false,
      normalEnabled: json['normalEnabled'] as bool? ?? false,
    );
  }
}
