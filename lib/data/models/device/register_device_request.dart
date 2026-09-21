class RegisterDeviceRequest {
  final String installationId;
  final String? pushToken;
  final String platform;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final String? appBuild;
  final String? locale;
  final String? timezone;
  final String? notificationPermission;

  const RegisterDeviceRequest({
    required this.installationId,
    required this.platform,
    this.pushToken,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
    this.appBuild,
    this.locale,
    this.timezone,
    this.notificationPermission,
  });

  Map<String, dynamic> toJson() {
    return {
      'installationId': installationId,
      if (pushToken != null) 'pushToken': pushToken,
      'platform': platform,
      if (deviceModel != null) 'deviceModel': deviceModel,
      if (osVersion != null) 'osVersion': osVersion,
      if (appVersion != null) 'appVersion': appVersion,
      if (appBuild != null) 'appBuild': appBuild,
      if (locale != null) 'locale': locale,
      if (timezone != null) 'timezone': timezone,
      if (notificationPermission != null)
        'notificationPermission': notificationPermission,
    };
  }
}
