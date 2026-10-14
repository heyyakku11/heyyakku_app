class SendOtpRequestModel {
  final String phoneNumber;
  final String? name;

  const SendOtpRequestModel({required this.phoneNumber, this.name});

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
    };
  }
}
