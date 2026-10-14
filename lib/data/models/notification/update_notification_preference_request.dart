class UpdateNotificationPreferenceRequest {
  final bool? pushEnabled;
  final bool? pollActivityEnabled;
  final bool? offersEnabled;

  const UpdateNotificationPreferenceRequest({
    this.pushEnabled,
    this.pollActivityEnabled,
    this.offersEnabled,
  });

  Map<String, dynamic> toJson() {
    return {
      if (pushEnabled != null) 'pushEnabled': pushEnabled,
      if (pollActivityEnabled != null)
        'pollActivityEnabled': pollActivityEnabled,
      if (offersEnabled != null) 'offersEnabled': offersEnabled,
    };
  }
}
