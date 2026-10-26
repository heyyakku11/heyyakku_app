class UserPlanResponse {
  final String id;
  final String code;
  final String name;
  final num price;
  final String currency;

  const UserPlanResponse({
    required this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.currency,
  });

  factory UserPlanResponse.fromJson(Map<String, dynamic> json) {
    return UserPlanResponse(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: json['price'] as num? ?? 0,
      currency: json['currency'] as String? ?? '',
    );
  }
}

class UserProfileResponse {
  final String id;
  final String status;
  final String phoneNumber;
  final String name;
  final String anonymousName;
  final DateTime? loginAt;
  final String? avatarUrl;
  final UserPlanResponse? currentPlan;

  /// The account-level push switch (on by default).
  final bool isPushAllowed;

  const UserProfileResponse({
    required this.id,
    required this.status,
    required this.phoneNumber,
    required this.name,
    required this.anonymousName,
    this.loginAt,
    this.avatarUrl,
    this.currentPlan,
    this.isPushAllowed = true,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    final plan = json['currentPlan'];
    return UserProfileResponse(
      id: json['id']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      anonymousName: json['anonymousName'] as String? ?? '',
      loginAt: _parseDate(json['loginAt']),
      avatarUrl: json['avatarUrl'] as String?,
      currentPlan: plan is Map<String, dynamic>
          ? UserPlanResponse.fromJson(plan)
          : null,
      isPushAllowed: json['isPushAllowed'] as bool? ?? true,
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
