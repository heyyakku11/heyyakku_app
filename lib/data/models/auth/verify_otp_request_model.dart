class VerifyOtpRequestModel {
  final String phone;
  final String otp;

  const VerifyOtpRequestModel({required this.phone, required this.otp});

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'otp': otp};
  }
}
