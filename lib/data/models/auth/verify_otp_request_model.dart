class VerifyOtpRequestModel {
  final String phoneNumber;
  final String otp;

  const VerifyOtpRequestModel({required this.phoneNumber, required this.otp});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber, 'otp': otp};
  }
}
