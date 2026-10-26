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

/// `data` of `GET /api/v1/users`, grouped by what the fields describe:
/// `profile` (how the user appears), `account` (status, phone, plan) and `stats` (counts and streak).
class UserProfileResponse {
  final UserProfileDetails profile;
  final UserAccountDetails account;
  final UserStatsDetails stats;

  const UserProfileResponse({
    required this.profile,
    required this.account,
    required this.stats,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      profile: UserProfileDetails.fromJson(_asMap(json['profile'])),
      account: UserAccountDetails.fromJson(_asMap(json['account'])),
      stats: UserStatsDetails.fromJson(_asMap(json['stats'])),
    );
  }
}

class UserProfileDetails {
  final String name;
  final String anonymousName;
  final String? avatarUrl;

  const UserProfileDetails({
    required this.name,
    required this.anonymousName,
    this.avatarUrl,
  });

  factory UserProfileDetails.fromJson(Map<String, dynamic> json) {
    return UserProfileDetails(
      name: json['name'] as String? ?? '',
      anonymousName: json['anonymousName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class UserAccountDetails {
  final String status;
  final String phoneNumber;
  final DateTime? loginAt;

  final UserPlanResponse? currentPlan;

  const UserAccountDetails({
    required this.status,
    required this.phoneNumber,
    this.loginAt,
    this.currentPlan,
  });

  factory UserAccountDetails.fromJson(Map<String, dynamic> json) {
    final plan = json['currentPlan'];
    return UserAccountDetails(
      status: json['status'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      loginAt: _parseDate(json['loginAt']),
      currentPlan: plan is Map<String, dynamic>
          ? UserPlanResponse.fromJson(plan)
          : null,
    );
  }
}

class UserStatsDetails {
  /// Polls created plus checks made.
  final int cardsMade;

  /// Votes cast on other people's polls and checks.
  final int votesCast;
  final UserStreakSummary streak;

  const UserStatsDetails({
    required this.cardsMade,
    required this.votesCast,
    required this.streak,
  });

  factory UserStatsDetails.fromJson(Map<String, dynamic> json) {
    return UserStatsDetails(
      cardsMade: json['cardsMade'] as int? ?? 0,
      votesCast: json['votesCast'] as int? ?? 0,
      streak: UserStreakSummary.fromJson(_asMap(json['streak'])),
    );
  }
}

class UserStreakSummary {
  /// The running streak today; zero once a whole day has been missed.
  final int currentStreak;
  final int longestStreak;

  const UserStreakSummary({
    required this.currentStreak,
    required this.longestStreak,
  });

  factory UserStreakSummary.fromJson(Map<String, dynamic> json) {
    return UserStreakSummary(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  return value is Map<String, dynamic> ? value : const <String, dynamic>{};
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
