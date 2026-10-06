class UpdateNotificationPreferenceRequest {
  final bool? pushEnabled;
  final bool? pollActivityEnabled;
  final bool? offersEnabled;
  final bool? alertsEnabled;
  final bool? normalEnabled;

  const UpdateNotificationPreferenceRequest({
    this.pushEnabled,
    this.pollActivityEnabled,
    this.offersEnabled,
    this.alertsEnabled,
    this.normalEnabled,
  });

  Map<String, dynamic> toJson() {
    return {
      if (pushEnabled != null) 'pushEnabled': pushEnabled,
      if (pollActivityEnabled != null)
        'pollActivityEnabled': pollActivityEnabled,
      if (offersEnabled != null) 'offersEnabled': offersEnabled,
      if (alertsEnabled != null) 'alertsEnabled': alertsEnabled,
      if (normalEnabled != null) 'normalEnabled': normalEnabled,
    };
  }
}
