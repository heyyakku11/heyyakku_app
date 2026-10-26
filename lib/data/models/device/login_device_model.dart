/// The installation that is signing in; sent inside the verify-OTP request so
/// the session and the device are bound in one atomic call. Permission and
/// push token are sent afterwards with `PATCH /devices/me`.
class LoginDeviceModel {
  final String installationId;
  final String platform;

  const LoginDeviceModel({
    required this.installationId,
    required this.platform,
  });

  Map<String, dynamic> toJson() {
    return {'installationId': installationId, 'platform': platform};
  }
}
