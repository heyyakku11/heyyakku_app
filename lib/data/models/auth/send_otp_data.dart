class SendOtpData {
  final String purpose;
  final int expiresInSeconds;

  const SendOtpData({
    required this.purpose,
    required this.expiresInSeconds,
  });

  factory SendOtpData.fromJson(Map<String, dynamic> json) {
    return SendOtpData(
      purpose: json['purpose'] as String? ?? '',
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 0,
    );
  }
}
