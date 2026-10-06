class DeviceResponse {
  final String installationId;
  final String platform;
  final String? notificationPermission;
  final bool isActive;
  final DateTime? lastSeenAt;

  const DeviceResponse({
    required this.installationId,
    required this.platform,
    required this.isActive,
    this.notificationPermission,
    this.lastSeenAt,
  });

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    return DeviceResponse(
      installationId: json['installationId'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      notificationPermission: json['notificationPermission'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      lastSeenAt: _parseDate(json['lastSeenAt']),
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
