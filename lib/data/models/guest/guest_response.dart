class GuestResponse {
  final String guestId;
  final DateTime expiresAt;
  final String? guestToken;

  const GuestResponse({
    required this.guestId,
    required this.expiresAt,
    this.guestToken,
  });

  factory GuestResponse.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['expiresAt'];
    DateTime expiresAt;
    if (expiresRaw is String) {
      expiresAt = DateTime.tryParse(expiresRaw) ?? DateTime.now().toUtc();
    } else {
      expiresAt = DateTime.now().toUtc();
    }

    return GuestResponse(
      guestId: json['guestId']?.toString() ?? '',
      expiresAt: expiresAt,
      guestToken: json['guestToken'] as String?,
    );
  }
}
