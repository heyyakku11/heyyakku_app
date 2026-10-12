class SendOtpRequestModel {
  final String phone;

  const SendOtpRequestModel({required this.phone});

  Map<String, dynamic> toJson() {
    return {'phone': phone};
  }
}
