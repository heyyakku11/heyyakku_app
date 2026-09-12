class SendOtpRequestModel {
  final String email;

  const SendOtpRequestModel({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}