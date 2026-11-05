class SendOtpRequestModel {
  final String phoneNumber;

  const SendOtpRequestModel({required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber};
  }
}
