class ResendOtpRequestModel {
  final String phoneNumber;

  const ResendOtpRequestModel({required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {'phoneNumber': phoneNumber};
  }
}
