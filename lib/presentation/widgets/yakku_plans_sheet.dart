import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/payments/checkout_user_messages.dart';
import 'package:yakku/core/payments/payment_confirm_result.dart';
import 'package:yakku/core/payments/payment_flow_controller.dart';
import 'package:yakku/core/payments/pending_purchase_intent.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/payments/payment_models.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/payments/entitlement_refresh.dart';
import 'package:yakku/presentation/payments/payment_flow_surfaces.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// Opens the plans sheet backed by `GET /api/v1/plans`.
///
/// Returns true only after backend verify reports Paid. Buying requires a
/// signed-in registered user; signed-out users are sent to sign-up with their
/// intended plan preserved.
///
/// Authenticated buy creates `POST /api/v1/payments/orders`, opens Razorpay
/// Checkout, then verifies via `POST /api/v1/payments/verify` (with bounded
/// status polling). Checkout success alone does not grant entitlement.
///
/// Pass [contentType] / [contentId] (`poll`|`check`) to include the permanent
/// `this_card` SKU for that card — unless the card is already unlocked (not
/// paused). Pass [includeThisCard] to force include/exclude when the caller
/// already knows access.
Future<bool> showYakkuPlans(
  BuildContext context, {
  String? contentType,
  String? contentId,
  bool? includeThisCard,
  UserPlanResponse? currentPlan,
  List<YakkuPlan>? catalog,
  String? initialPlanCode,
}) async {
  final order = await showModalBottomSheet<CreatePaymentOrderResponse>(
    context: context,
    backgroundColor: YakkuPalette.cream,
    isScrollControlled: true,
    useSafeArea: true,
    // One smooth motion on open (a bit slower); quicker dismiss.
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 560),
      reverseDuration: Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOut,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => YakkuPlansSheet(
      contentType: contentType,
      contentId: contentId,
      includeThisCardOverride: includeThisCard,
      initialCurrentPlan: currentPlan,
      initialCatalog: catalog,
      initialPlanCode: initialPlanCode,
    ),
  );
  if (order == null) return false;
  if (!context.mounted) return false;

  final scope = AppScope.of(context);
  if (scope.paymentFlow.isBusy) {
    AppToast.show('A payment is already in progress.');
    return false;
  }

  final dismissOpening = showPaymentProgressDialog(
    context,
    message: 'Opening payment…',
  );

  void onCheckoutChanged() {
    if (!scope.razorpayCheckout.isOpening) {
      dismissOpening();
    }
  }

  scope.razorpayCheckout.addListener(onCheckoutChanged);
  RazorpayCheckoutResult result;
  try {
    result = await scope.paymentFlow.openCheckout(
      order,
      contact: scope.authController.phoneNumber,
    );
  } catch (error) {
    dismissOpening();
    if (context.mounted) {
      await showPaymentOutcomeDialog(
        context,
        kind: PaymentOutcomeKind.failure,
        title: 'Could not open payment',
        message: CheckoutUserMessages.forOpenFailure(error),
      );
    }
    return false;
  } finally {
    scope.razorpayCheckout.removeListener(onCheckoutChanged);
    dismissOpening();
  }

  if (result is RazorpayCheckoutFailure) {
    if (!context.mounted) return false;
    // Capture may have succeeded even if Checkout reported cancel/error.
    final dismissChecking = showPaymentProgressDialog(
      context,
      message: 'Checking payment…',
    );
    PaymentConfirmResult reconciled;
    try {
      reconciled = await scope.paymentFlow.reconcileAfterCheckoutClosed(
        orderId: result.internalOrderId ?? order.orderId,
      );
    } finally {
      dismissChecking();
    }

    if (reconciled is PaymentConfirmFulfilled) {
      if (context.mounted) {
        await presentPaymentConfirmOutcome(context, reconciled);
      }
      await _refreshEntitlementsAfterFulfillment(
        scope,
        fulfilled: reconciled,
        contentType: contentType,
        contentId: contentId,
      );
      return true;
    }

    if (result.isCancelled) {
      // Stay quiet when the user backed out and backend is not Paid.
      return false;
    }

    if (context.mounted) {
      final checkoutMsg = CheckoutUserMessages.forCheckoutResult(result);
      final pending = reconciled is PaymentConfirmPending;
      final backendMsg = switch (reconciled) {
        PaymentConfirmPending(:final message) => message,
        PaymentConfirmFailed(:final message) => message,
        PaymentConfirmFulfilled() => null,
      };
      final message = checkoutMsg ??
          backendMsg ??
          'Payment failed. Please try again.';
      final retry = await showPaymentOutcomeDialog(
        context,
        kind: pending
            ? PaymentOutcomeKind.pending
            : PaymentOutcomeKind.failure,
        title: pending ? 'Payment not completed' : 'Payment failed',
        message: message,
        primaryLabel: pending ? 'Close' : 'OK',
        retryLabel: pending ? 'Check again' : null,
      );
      if (retry && context.mounted) {
        return _retryPendingStatus(
          context,
          scope: scope,
          orderId: result.internalOrderId ?? order.orderId,
          contentType: contentType,
          contentId: contentId,
        );
      }
    }
    return false;
  }

  if (result is! RazorpayCheckoutSuccess) return false;
  if (!context.mounted) return false;

  final dismissConfirming = showPaymentProgressDialog(
    context,
    message: 'Confirming payment…',
  );
  PaymentConfirmResult confirmed;
  try {
    confirmed = await scope.paymentFlow.confirmCheckoutSuccess(result);
  } finally {
    dismissConfirming();
  }

  if (!context.mounted) return false;

  if (confirmed is PaymentConfirmFulfilled) {
    await presentPaymentConfirmOutcome(context, confirmed);
    await _refreshEntitlementsAfterFulfillment(
      scope,
      fulfilled: confirmed,
      contentType: contentType,
      contentId: contentId,
    );
    return true;
  }

  final retry = await presentPaymentConfirmOutcome(context, confirmed);
  if (retry && context.mounted) {
    return _retryPendingStatus(
      context,
      scope: scope,
      orderId: confirmed is PaymentConfirmPending
          ? confirmed.orderId
          : (result.internalOrderId ?? order.orderId),
      contentType: contentType,
      contentId: contentId,
    );
  }
  return false;
}

Future<bool> _retryPendingStatus(
  BuildContext context, {
  required AppScope scope,
  required String orderId,
  String? contentType,
  String? contentId,
}) async {
  if (orderId.isEmpty) return false;
  final dismiss = showPaymentProgressDialog(
    context,
    message: 'Checking payment…',
  );
  PaymentConfirmResult result;
  try {
    result = await scope.paymentFlow.refreshOrderStatus(orderId);
  } finally {
    dismiss();
  }
  if (!context.mounted) return false;

  if (result is PaymentConfirmFulfilled) {
    await presentPaymentConfirmOutcome(context, result);
    await _refreshEntitlementsAfterFulfillment(
      scope,
      fulfilled: result,
      contentType: contentType,
      contentId: contentId,
    );
    return true;
  }

  await presentPaymentConfirmOutcome(context, result);
  return false;
}

Future<void> _refreshEntitlementsAfterFulfillment(
  AppScope scope, {
  required PaymentConfirmFulfilled fulfilled,
  String? contentType,
  String? contentId,
}) {
  return EntitlementRefresh.afterFulfillment(
    userRemote: scope.userRemote,
    personalityCards: scope.personalityCards,
    askBack: scope.askBack,
    askBackInbox: scope.askBackInbox,
    contentType: fulfilled.contentType ?? contentType,
    contentId: fulfilled.contentId ?? contentId,
  );
}

/// "See what they really think": purchasable plans from the backend catalog.
class YakkuPlansSheet extends StatefulWidget {
  const YakkuPlansSheet({
    super.key,
    this.contentType,
    this.contentId,
    this.includeThisCardOverride,
    this.initialCurrentPlan,
    this.initialCatalog,
    this.initialPlanCode,
  });

  final String? contentType;
  final String? contentId;

  /// When set, skips the card-access lookup for whether to offer `this_card`.
  final bool? includeThisCardOverride;

  final UserPlanResponse? initialCurrentPlan;
  final List<YakkuPlan>? initialCatalog;
  final String? initialPlanCode;

  bool get hasCardContext =>
      contentType != null &&
      contentType!.isNotEmpty &&
      contentId != null &&
      contentId!.isNotEmpty;

  @override
  State<YakkuPlansSheet> createState() => _YakkuPlansSheetState();
}

class _YakkuPlansSheetState extends State<YakkuPlansSheet> {
  static const _ink = YakkuPalette.textPrimary;
  static const _night = Color(0xFF211A1D);

  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  List<YakkuPlan> _plans = const [];
  UserPlanResponse? _currentPlan;
  YakkuPlan? _picked;

  String get _effectiveCode => effectivePlanCode(
        code: _currentPlan?.code,
        isExpired: _currentPlan?.isExpired ?? false,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final seedCatalog = widget.initialCatalog;
    var current = widget.initialCurrentPlan;
    List<YakkuPlan> catalog = seedCatalog ?? const [];

    try {
      final scope = AppScope.of(context);
      if (seedCatalog == null || seedCatalog.isEmpty) {
        catalog = await scope.userRemote.listPlans();
      }
      if (current == null) {
        try {
          if (scope.authController.isLoggedIn) {
            final me = await scope.userRemote.getMe();
            current = me.account.currentPlan;
          }
        } catch (_) {
          // Sheet still works from catalog; purchase rules fall back to Free.
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load plans. Try again.',
        ).message;
        _plans = const [];
        _picked = null;
      });
      return;
    }

    if (!mounted) return;

    // Offer this_card only for locked (or paused) cards. An active unlock must
    // not re-sell permanent access for the same card.
    var includeThisCard = widget.includeThisCardOverride ?? widget.hasCardContext;
    if (includeThisCard && widget.includeThisCardOverride == null) {
      try {
        final access = await AppScope.of(context).askBack.getCardAccess(
          widget.contentType!,
          widget.contentId!,
        );
        if (access.unlocked && !access.paused) {
          includeThisCard = false;
        }
      } catch (_) {
        // Keep this_card candidate; buy still fails server-side if unlocked.
      }
    }
    if (!mounted) return;

    final offers = purchasablePlansForSheet(
      catalog: catalog,
      includeThisCard: includeThisCard,
    );
    final effective = effectivePlanCode(
      code: current?.code,
      isExpired: current?.isExpired ?? false,
    );
    setState(() {
      _loading = false;
      _error = null;
      _plans = offers;
      _currentPlan = current;
      _picked = _defaultPick(offers, effective);
    });
  }

  YakkuPlan? _defaultPick(List<YakkuPlan> offers, String effectiveCode) {
    if (offers.isEmpty) return null;
    final preferredCode = widget.initialPlanCode;
    if (preferredCode != null) {
      for (final plan in offers) {
        if (plan.code == preferredCode &&
            canPurchasePlan(plan: plan, effectiveCode: effectiveCode)) {
          return plan;
        }
      }
    }
    for (final plan in offers) {
      if (plan.isLite &&
          canPurchasePlan(plan: plan, effectiveCode: effectiveCode)) {
        return plan;
      }
    }
    for (final plan in offers) {
      if (canPurchasePlan(plan: plan, effectiveCode: effectiveCode)) {
        return plan;
      }
    }
    return offers.first;
  }

  PlanPurchaseAvailability _availability(YakkuPlan plan) {
    return planPurchaseAvailability(plan: plan, effectiveCode: _effectiveCode);
  }

  String _buttonLabel(YakkuPlan plan) {
    return switch (_availability(plan)) {
      PlanPurchaseAvailability.available => plan.purchaseButtonLabel,
      PlanPurchaseAvailability.current => 'Current plan',
      PlanPurchaseAvailability.downgrade => 'Downgrade not available',
      PlanPurchaseAvailability.unavailable => 'Not available',
    };
  }

  Future<void> _onBuy() async {
    final plan = _picked;
    if (plan == null || _purchasing) return;
    if (!canPurchasePlan(plan: plan, effectiveCode: _effectiveCode)) return;

    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) {
      final router = GoRouter.of(context);
      await scope.pendingPurchase.save(
        PendingPurchaseIntent(
          planId: plan.id,
          planCode: plan.code,
          planName: plan.name,
          savedAt: DateTime.now().toUtc(),
          contentType: widget.contentType,
          contentId: widget.contentId,
        ),
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
      AppToast.show('Sign in to continue with ${plan.name}');
      router.go(AppRoutes.signUp);
      return;
    }

    setState(() => _purchasing = true);
    final started = await scope.paymentFlow.createOrder(
      plan: plan,
      contentType: widget.contentType,
      contentId: widget.contentId,
    );
    if (!mounted) return;

    if (started is PaymentOrderStartFailure) {
      setState(() => _purchasing = false);
      if (!started.isBusy && mounted) {
        await showPaymentOutcomeDialog(
          context,
          kind: PaymentOutcomeKind.failure,
          title: 'Could not start payment',
          message: started.message,
        );
      }
      return;
    }

    if (started is PaymentOrderStartSuccess) {
      Navigator.of(context).pop(started.order);
      return;
    }

    setState(() => _purchasing = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: YakkuPalette.sheetHandle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'See what they really think',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: _ink,
                  tooltip: 'Close',
                ),
              ],
            ),
            if (_currentPlan != null) ...[
              const SizedBox(height: 4),
              Text(
                _currentPlanLine(_currentPlan!),
                style: const TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else if (_plans.isEmpty)
              const _ErrorState(
                message: 'No plans are available right now.',
                onRetry: null,
              )
            else ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _plans.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _PlanCard(
                          plan: _plans[i],
                          selected: _plans[i].id == _picked?.id,
                          availability: _availability(_plans[i]),
                          onTap: () => setState(() => _picked = _plans[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ComparisonTable(plans: _plans, picked: _picked),
              const SizedBox(height: 16),
              const Text(
                "See what they won't say to your face",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final canBuy = !_purchasing &&
                      _picked != null &&
                      canPurchasePlan(
                        plan: _picked!,
                        effectiveCode: _effectiveCode,
                      );
                  final label = _purchasing
                      ? 'Starting payment'
                      : _picked == null
                          ? 'Select a plan'
                          : _buttonLabel(_picked!);
                  return Semantics(
                    button: true,
                    enabled: canBuy,
                    label: label,
                    child: FilledButton(
                      onPressed: canBuy ? _onBuy : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: YakkuPalette.primary,
                        disabledBackgroundColor: YakkuPalette.primary
                            .withValues(alpha: 0.35),
                        foregroundColor: YakkuPalette.white,
                        disabledForegroundColor: YakkuPalette.white,
                        minimumSize: const Size.fromHeight(58),
                        shape: const StadiumBorder(),
                      ),
                      child: _purchasing
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: YakkuPalette.white,
                              ),
                            )
                          : Text(
                              label,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              const Text(
                "One-time payment. Doesn't renew.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _currentPlanLine(UserPlanResponse plan) {
    final badge = planBadgeLabel(
      code: plan.code,
      name: plan.name,
      isExpired: plan.isExpired,
    );
    final expires = plan.expiresAt;
    if (plan.isExpired || expires == null) {
      return 'Your plan · $badge';
    }
    final local = expires.toLocal();
    final stamp =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    return 'Your plan · $badge · ends $stamp';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.availability,
    required this.onTap,
  });

  final YakkuPlan plan;
  final bool selected;
  final PlanPurchaseAvailability availability;
  final VoidCallback onTap;

  String? get _badge {
    if (plan.isLove) return 'Unlimited';
    if (plan.isLite) return 'Popular';
    return null;
  }

  Color get _fill {
    if (plan.isLove) return YakkuPalette.butter;
    if (plan.isLite) return YakkuPalette.pillPink;
    return YakkuPalette.white;
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final dark = plan.isLove;
    final isCurrent = availability == PlanPurchaseAvailability.current;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: _fill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected
                    ? _YakkuPlansSheetState._night
                    : YakkuPalette.roseBorder,
                width: selected ? 2 : 1.2,
              ),
            ),
            child: InkWell(
              key: ValueKey('plan-${plan.code}'),
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.isThisCard ? 'This card' : plan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: YakkuPalette.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _Radio(selected: selected, dark: dark),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCurrent ? 'Current plan' : plan.detailLine,
                      style: const TextStyle(
                        color: YakkuPalette.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      plan.formattedPrice,
                      style: TextStyle(
                        color: plan.isLite
                            ? YakkuPalette.primary
                            : YakkuPalette.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: dark
                      ? _YakkuPlansSheetState._night
                      : YakkuPalette.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: dark ? YakkuPalette.Gold : YakkuPalette.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.dark});

  final bool selected;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? _YakkuPlansSheetState._night
            : (dark ? YakkuPalette.butter : YakkuPalette.white),
        border: selected
            ? null
            : Border.all(color: YakkuPalette.roseBorder, width: 1.2),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 15, color: YakkuPalette.white)
          : null,
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.tint,
    required this.ink,
    required this.title,
    this.subtitle,
    required this.valuesFor,
  });

  final IconData icon;
  final Color tint;
  final Color ink;
  final String title;
  final String? subtitle;
  final ({String? main, String? note}) Function(YakkuPlan plan) valuesFor;
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.plans, required this.picked});

  final List<YakkuPlan> plans;
  final YakkuPlan? picked;

  static const _rowHeight = 64.0;
  static const _headHeight = 46.0;

  static final _features = <_Feature>[
    _Feature(
      icon: Icons.reply_rounded,
      tint: Color(0xFFFFEFC2),
      ink: Color(0xFF8A6A12),
      title: 'Ask back everyone',
      valuesFor: _askBackValue,
    ),
    _Feature(
      icon: Icons.chat_bubble_outline_rounded,
      tint: YakkuPalette.pillPink,
      ink: YakkuPalette.primary,
      title: 'Every reason',
      valuesFor: (_) => (main: null, note: null),
    ),
    _Feature(
      icon: Icons.edit_outlined,
      tint: YakkuPalette.accentPurple,
      ink: YakkuPalette.purpleInk,
      title: 'Options',
      subtitle: 'others added',
      valuesFor: (_) => (main: null, note: null),
    ),
    _Feature(
      icon: Icons.copy_rounded,
      tint: YakkuPalette.mint,
      ink: YakkuPalette.forestGreen,
      title: 'Cards',
      subtitle: 'unlocked',
      valuesFor: _cardsValue,
    ),
  ];

  static ({String? main, String? note}) _askBackValue(YakkuPlan plan) {
    final limit = plan.askBackMessageLimit;
    if (limit == null) return (main: 'Unlimited', note: null);
    if (plan.isThisCard) {
      return (main: '$limit ${limit == 1 ? 'time' : 'times'}', note: 'each');
    }
    return (main: '$limit ${limit == 1 ? 'time' : 'times'}', note: 'each');
  }

  static ({String? main, String? note}) _cardsValue(YakkuPlan plan) {
    if (plan.isThisCard) return (main: '1', note: 'this one');
    final tickets = plan.unlockTickets;
    if (tickets == null) {
      final days = plan.durationDays;
      return (
        main: 'Unlimited',
        note: days == null ? null : 'in $days days',
      );
    }
    final days = plan.durationDays;
    return (
      main: '$tickets',
      note: days == null ? null : 'in $days days',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YakkuPalette.roseBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: _headHeight + _rowHeight * _features.length,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 11, child: _labels()),
            for (final plan in plans)
              Expanded(flex: 6, child: _column(plan)),
          ],
        ),
      ),
    );
  }

  Widget _labels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: _headHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'WHAT YOU GET',
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
        for (final feature in _features)
          Container(
            height: _rowHeight,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: YakkuPalette.roseBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: feature.tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(feature.icon, size: 18, color: feature.ink),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: const TextStyle(
                          color: YakkuPalette.textPrimary,
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (feature.subtitle != null)
                        Text(
                          feature.subtitle!,
                          style: const TextStyle(
                            color: YakkuPalette.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _column(YakkuPlan plan) {
    final selected = plan.id == picked?.id;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: selected ? 1 : 0),
      decoration: BoxDecoration(
        color: selected ? _YakkuPlansSheetState._night : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            height: _headHeight,
            child: Center(
              child: Text(
                plan.shortLabel,
                style: TextStyle(
                  color: selected
                      ? YakkuPalette.Gold
                      : YakkuPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          for (final feature in _features)
            Container(
              height: _rowHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: selected
                        ? const Color(0x33FFFFFF)
                        : YakkuPalette.roseBorder,
                  ),
                ),
              ),
              child: _value(feature, feature.valuesFor(plan), selected),
            ),
        ],
      ),
    );
  }

  Widget _value(
    _Feature feature,
    ({String? main, String? note}) value,
    bool selected,
  ) {
    final main = value.main;
    if (main == null) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? YakkuPalette.Gold : feature.tint,
        ),
        child: Icon(
          Icons.check_rounded,
          size: 18,
          color: selected ? _YakkuPlansSheetState._night : feature.ink,
        ),
      );
    }
    final big = main.length > 6;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          main,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? YakkuPalette.Gold
                : (feature.title == 'Cards'
                      ? YakkuPalette.forestGreen
                      : YakkuPalette.textPrimary),
            fontSize: big ? 12 : 14,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (value.note != null)
          Text(
            value.note!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? YakkuPalette.white : YakkuPalette.textSecondary,
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
