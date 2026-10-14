class UserProfileResponse {
  final String id;
  final String status;
  final String phoneNumber;
  final String name;
  final String anonymousName;
  final DateTime? loginAt;
  final String? avatarUrl;

  const UserProfileResponse({
    required this.id,
    required this.status,
    required this.phoneNumber,
    required this.name,
    required this.anonymousName,
    this.loginAt,
    this.avatarUrl,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      id: json['id']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      anonymousName: json['anonymousName'] as String? ?? '',
      loginAt: _parseDate(json['loginAt']),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
