/// A subscription plan from `GET /api/v1/plans`.
class YakkuPlan {
  const YakkuPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.priceMinor,
    required this.currency,
    this.durationDays,
    this.unlockTickets,
    this.askBackMessageLimit,
  });

  static const freeCode = 'free';
  static const thisCardCode = 'this_card';
  static const liteCode = 'yakku_lite';
  static const loveCode = 'yakku_love';

  /// Subscription hierarchy: free → lite → love. Catalog-only `this_card` is excluded.
  static int sortKey(String code) => switch (code) {
        freeCode => 1,
        liteCode => 2,
        loveCode => 3,
        _ => 99,
      };

  /// True for plans shown as You-tab upgrades (not free, not one-card SKU).
  bool get isSubscriptionUpgrade => isLite || isLove;

  final String id;
  final String code;
  final String name;

  /// Price in the smallest currency unit (paise for INR).
  final int priceMinor;
  final String currency;
  final int? durationDays;

  /// Cards unlockable per activation; null means unlimited.
  final int? unlockTickets;
  final int? askBackMessageLimit;

  bool get isFree => code == freeCode;
  bool get isLite => code == liteCode;
  bool get isLove => code == loveCode;

  String get formattedPrice {
    final major = (priceMinor / 100).round();
    if (currency.toUpperCase() == 'INR' || currency.isEmpty) {
      return '₹$major';
    }
    return '$currency $major';
  }

  /// e.g. "3 cards · 7 days" or "Every card · 30 days".
  String get detailLine {
    final cards = unlockTickets == null
        ? 'Every card'
        : '$unlockTickets ${unlockTickets == 1 ? 'card' : 'cards'}';
    if (durationDays == null) return cards;
    return '$cards · $durationDays days';
  }

  factory YakkuPlan.fromJson(Map<String, dynamic> json) {
    return YakkuPlan(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceMinor: json['priceMinor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      durationDays: json['durationDays'] as int?,
      unlockTickets: json['unlockTickets'] as int?,
      askBackMessageLimit: json['askBackMessageLimit'] as int?,
    );
  }
}

/// Resolves the user's effective plan code for hierarchy (expired → free).
String effectivePlanCode({
  required String? code,
  required bool isExpired,
}) {
  if (isExpired || code == null || code.isEmpty) {
    return YakkuPlan.freeCode;
  }
  return code;
}

/// Paid plans strictly above the user's effective plan, in hierarchy order.
List<YakkuPlan> plansAboveCurrent({
  required List<YakkuPlan> catalog,
  required String effectiveCode,
}) {
  final current = YakkuPlan.sortKey(effectiveCode);
  return catalog
      .where(
        (plan) =>
            plan.isSubscriptionUpgrade &&
            YakkuPlan.sortKey(plan.code) > current,
      )
      .toList()
    ..sort((a, b) => YakkuPlan.sortKey(a.code).compareTo(YakkuPlan.sortKey(b.code)));
}

/// Short badge label: FREE / YAKKU LITE / YAKKU LOVE.
String planBadgeLabel({
  required String? code,
  required String? name,
  required bool isExpired,
}) {
  final effective = effectivePlanCode(code: code, isExpired: isExpired);
  if (name != null && name.trim().isNotEmpty && !isExpired) {
    return name.trim().toUpperCase();
  }
  return switch (effective) {
    YakkuPlan.liteCode => 'YAKKU LITE',
    YakkuPlan.loveCode => 'YAKKU LOVE',
    _ => 'FREE',
  };
}
