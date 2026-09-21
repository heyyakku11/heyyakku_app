class UserProfileResponse {
  final String id;
  final String status;
  final String email;
  final String displayName;
  final DateTime? lastLoginAt;
  final String? avatarUrl;

  const UserProfileResponse({
    required this.id,
    required this.status,
    required this.email,
    required this.displayName,
    this.lastLoginAt,
    this.avatarUrl,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      id: json['id']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      lastLoginAt: _parseDate(json['lastLoginAt']),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
