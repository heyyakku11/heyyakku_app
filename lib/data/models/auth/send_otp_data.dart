class SendOtpData {
  final String purpose;
  final int expiresInSeconds;

  const SendOtpData({required this.purpose, required this.expiresInSeconds});

  int get expiresInMinutes {
    if (expiresInSeconds <= 0) return 0;
    return (expiresInSeconds / 60).ceil();
  }

  factory SendOtpData.fromJson(Map<String, dynamic> json) {
    return SendOtpData(
      purpose: json['purpose'] as String? ?? '',
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 0,
    );
  }
}
