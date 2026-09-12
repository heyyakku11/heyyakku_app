class VerifyOtpRequestModel {
  final String email;
  final String otp;

  const VerifyOtpRequestModel({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}