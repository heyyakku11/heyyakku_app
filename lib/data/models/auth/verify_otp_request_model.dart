import 'package:yakku/data/models/device/login_device_model.dart';

class VerifyOtpRequestModel {
  final String phoneNumber;
  final String otp;

  /// The installation signing in. Optional: when present the server binds the
  /// new session to it atomically with the OTP check.
  final LoginDeviceModel? device;

  const VerifyOtpRequestModel({
    required this.phoneNumber,
    required this.otp,
    this.device,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'otp': otp,
      if (device != null) 'device': device!.toJson(),
    };
  }
}
