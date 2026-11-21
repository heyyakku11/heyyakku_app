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
  bool get isThisCard => code == thisCardCode;

  /// Paid catalog SKUs shown in the plans sheet (not Free).
  bool get isPurchasableSku => isThisCard || isLite || isLove;

  String get formattedPrice {
    final major = (priceMinor / 100).round();
    if (currency.toUpperCase() == 'INR' || currency.isEmpty) {
      return '₹$major';
    }
    return '$currency $major';
  }

  /// Short column label for the comparison table.
  String get shortLabel {
    if (isThisCard) return 'Card';
    if (isLite) return 'Lite';
    if (isLove) return 'Love';
    return name;
  }

  /// e.g. "3 cards · 7 days" or "Every card · 30 days".
  String get detailLine {
    if (isThisCard) return 'One card';
    final cards = unlockTickets == null
        ? 'Every card'
        : '$unlockTickets ${unlockTickets == 1 ? 'card' : 'cards'}';
    if (durationDays == null) return cards;
    return '$cards · $durationDays days';
  }

  /// Buy button label when the plan can be purchased.
  String get purchaseButtonLabel {
    final title = isThisCard ? 'this card' : name;
    return 'Get $title · $formattedPrice';
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

/// Why a purchase CTA is enabled or disabled in the plans sheet.
enum PlanPurchaseAvailability {
  /// User may start checkout (backend still authoritative).
  available,

  /// This subscription is already the active plan.
  current,

  /// Active Love cannot move down to Lite.
  downgrade,

  /// Not a paid SKU / not offered in this context.
  unavailable,
}

/// UI purchase eligibility from the effective plan. Backend enforces the same
/// rules again on order creation.
PlanPurchaseAvailability planPurchaseAvailability({
  required YakkuPlan plan,
  required String effectiveCode,
}) {
  if (!plan.isPurchasableSku || plan.priceMinor <= 0) {
    return PlanPurchaseAvailability.unavailable;
  }
  if (plan.isThisCard) {
    return PlanPurchaseAvailability.available;
  }
  final current = YakkuPlan.sortKey(effectiveCode);
  final target = YakkuPlan.sortKey(plan.code);
  if (target == current) return PlanPurchaseAvailability.current;
  if (target < current) return PlanPurchaseAvailability.downgrade;
  return PlanPurchaseAvailability.available;
}

bool canPurchasePlan({
  required YakkuPlan plan,
  required String effectiveCode,
}) {
  return planPurchaseAvailability(
        plan: plan,
        effectiveCode: effectiveCode,
      ) ==
      PlanPurchaseAvailability.available;
}

/// Paid plans for the sheet: Lite/Love always; `this_card` only with card context.
List<YakkuPlan> purchasablePlansForSheet({
  required List<YakkuPlan> catalog,
  required bool includeThisCard,
}) {
  final plans = catalog.where((plan) {
    if (!plan.isPurchasableSku || plan.priceMinor <= 0) return false;
    if (plan.isThisCard) return includeThisCard;
    return plan.isSubscriptionUpgrade;
  }).toList();
  plans.sort((a, b) {
    int rank(YakkuPlan plan) {
      if (plan.isThisCard) return 0;
      if (plan.isLite) return 1;
      if (plan.isLove) return 2;
      return 99;
    }

    return rank(a).compareTo(rank(b));
  });
  return plans;
}
