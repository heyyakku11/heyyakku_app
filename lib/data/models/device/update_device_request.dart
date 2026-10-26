/// Body of `PATCH /devices/me`. Only non-null fields are sent; the server
/// leaves everything else unchanged.
class UpdateDeviceRequest {
  final String? pushToken;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final String? appBuild;
  final String? locale;
  final String? timezone;
  final String? notificationPermission;

  const UpdateDeviceRequest({
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
      if (pushToken != null) 'pushToken': pushToken,
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
