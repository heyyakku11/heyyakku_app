import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/payments/payment_confirm_result.dart';
import 'package:yakku/core/payments/pending_payment_store.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/payments/payment_models.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/payments/entitlement_refresh.dart';
import 'package:yakku/presentation/payments/payment_flow_surfaces.dart';
import 'package:yakku/presentation/payments/payment_status_labels.dart';
import 'package:yakku/presentation/widgets/skeleton.dart';

/// Paginated payment history + recovery for interrupted / processing orders.
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final List<PaymentHistoryItem> _items = [];
  PendingPayment? _pendingLocal;
  bool _loading = true;
  bool _loadingMore = false;
  bool _checking = false;
  String? _error;
  int _page = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadPendingLocal(), _loadFirstPage()]);
  }

  Future<void> _loadPendingLocal() async {
    try {
      final pending = await AppScope.of(context).pendingPayments.read();
      if (!mounted) return;
      setState(() => _pendingLocal = pending);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingLocal = null);
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _hasMore = true;
      _items.clear();
    });
    await _loadMore(reset: true);
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loadingMore) return;
    if (!reset && !_hasMore) return;

    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final nextPage = reset ? 1 : _page + 1;
      final page = await AppScope.of(context).payments.getHistory(
        page: nextPage,
        pageSize: 20,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load payment history.',
        ).message;
      });
    }
  }

  Future<void> _checkPendingLocal() async {
    if (_checking) return;
    setState(() => _checking = true);
    final dismiss = showPaymentProgressDialog(
      context,
      message: 'Checking payment…',
    );
    try {
      final scope = AppScope.of(context);
      final result = await scope.paymentFlow.reconcilePendingPayment();
      dismiss();
      if (!mounted) return;
      await _handleConfirmResult(result);
      await _loadPendingLocal();
      await _loadFirstPage();
    } finally {
      dismiss();
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _checkHistoryItem(PaymentHistoryItem item) async {
    if (_checking) return;
    setState(() => _checking = true);
    final dismiss = showPaymentProgressDialog(
      context,
      message: 'Checking payment…',
    );
    try {
      final scope = AppScope.of(context);
      final pending = await scope.pendingPayments.read();
      PaymentConfirmResult result;
      if (pending != null &&
          pending.orderId == item.orderId &&
          pending.hasVerifyPayload) {
        result = (await scope.paymentFlow.reconcilePendingPayment()) ??
            await scope.paymentFlow.refreshOrderStatus(item.orderId);
      } else {
        result = await scope.paymentFlow.refreshOrderStatus(item.orderId);
      }
      dismiss();
      if (!mounted) return;
      await _handleConfirmResult(result);
      await _loadPendingLocal();
      await _loadFirstPage();
    } finally {
      dismiss();
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _handleConfirmResult(PaymentConfirmResult? result) async {
    if (!mounted) return;
    if (result == null) {
      await showPaymentOutcomeDialog(
        context,
        kind: PaymentOutcomeKind.pending,
        title: 'Nothing to confirm',
        message: 'No payment is waiting to be confirmed.',
      );
      return;
    }

    final retry = await presentPaymentConfirmOutcome(context, result);
    if (result is PaymentConfirmFulfilled && mounted) {
      final scope = AppScope.of(context);
      await EntitlementRefresh.afterFulfillment(
        userRemote: scope.userRemote,
        personalityCards: scope.personalityCards,
        askBack: scope.askBack,
        askBackInbox: scope.askBackInbox,
        contentType: result.contentType,
        contentId: result.contentId,
      );
    }

    if (retry && mounted) {
      final orderId = switch (result) {
        PaymentConfirmPending(:final orderId) => orderId,
        PaymentConfirmFailed(:final orderId) => orderId,
        PaymentConfirmFulfilled(:final orderId) => orderId,
      };
      if (orderId == null || orderId.isEmpty) return;
      setState(() => _checking = true);
      final dismiss = showPaymentProgressDialog(
        context,
        message: 'Checking payment…',
      );
      try {
        final again =
            await AppScope.of(context).paymentFlow.refreshOrderStatus(orderId);
        dismiss();
        if (!mounted) return;
        await _handleConfirmResult(again);
        await _loadPendingLocal();
        await _loadFirstPage();
      } finally {
        dismiss();
        if (mounted) setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      appBar: AppBar(
        backgroundColor: YakkuPalette.cream,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const FaIcon(
            FontAwesomeIcons.chevronLeft,
            size: 16,
            color: YakkuPalette.Ink,
          ),
        ),
        title: const Text(
          'Payments',
          style: TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadPendingLocal();
          await _loadFirstPage();
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty && _error == null) {
      return const _PaymentsHistorySkeleton();
    }

    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _loadFirstPage,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (_pendingLocal != null) ...[
          _PendingRecoveryBanner(
            pending: _pendingLocal!,
            busy: _checking,
            onCheck: _checkPendingLocal,
          ),
          const SizedBox(height: 14),
        ],
        if (_items.isEmpty)
          SizedBox(
            // Leave room for the app bar + optional recovery banner while
            // still centering the empty state on a pull-to-refresh ListView.
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: const _PaymentsEmptyState(),
          )
        else
          for (final item in _items) ...[
            _PaymentHistoryTile(
              item: item,
              busy: _checking,
              onCheckStatus: PaymentStatusLabels.canCheckStatus(item.status)
                  ? () => _checkHistoryItem(item)
                  : null,
            ),
            const SizedBox(height: 10),
          ],
        if (_loadingMore) ...[
          const SizedBox(height: 4),
          const SkeletonPulse(child: _PaymentHistoryTileSkeleton()),
        ] else if (_hasMore) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _loadMore(),
              child: const Text('Load more'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Placeholder rows shaped like payment history tiles.
class _PaymentsHistorySkeleton extends StatelessWidget {
  const _PaymentsHistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: const [
          _PaymentHistoryTileSkeleton(),
          SizedBox(height: 10),
          _PaymentHistoryTileSkeleton(),
          SizedBox(height: 10),
          _PaymentHistoryTileSkeleton(),
          SizedBox(height: 10),
          _PaymentHistoryTileSkeleton(),
          SizedBox(height: 10),
          _PaymentHistoryTileSkeleton(),
        ],
      ),
    );
  }
}

class _PaymentHistoryTileSkeleton extends StatelessWidget {
  const _PaymentHistoryTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YakkuPalette.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: YakkuPalette.roseBorder, width: 1.2),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 42, height: 42, radius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 120, height: 14, radius: 7),
                      SizedBox(height: 8),
                      SkeletonBox(width: 72, height: 11, radius: 6),
                    ],
                  ),
                ),
                SkeletonBox(width: 52, height: 18, radius: 8),
              ],
            ),
            SizedBox(height: 14),
            SkeletonBox(height: 36, radius: 12),
          ],
        ),
      ),
    );
  }
}

class _PaymentsEmptyState extends StatelessWidget {
  const _PaymentsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: YakkuPalette.Blush.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const FaIcon(
              FontAwesomeIcons.receipt,
              size: 32,
              color: YakkuPalette.Raspberry,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'No payments yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Plan upgrades and card unlocks will show up here once you buy them.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRecoveryBanner extends StatelessWidget {
  const _PendingRecoveryBanner({
    required this.pending,
    required this.busy,
    required this.onCheck,
  });

  final PendingPayment pending;
  final bool busy;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final title = pending.planName.isNotEmpty
        ? pending.planName
        : 'Recent payment';
    return Material(
      color: YakkuPalette.white,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment may still be processing',
              style: TextStyle(
                color: YakkuPalette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$title · check status without starting a new payment.',
              style: const TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                enabled: !busy,
                label: busy
                    ? 'Checking payment status'
                    : 'Check payment status',
                child: FilledButton(
                  onPressed: busy ? null : onCheck,
                  style: FilledButton.styleFrom(
                    backgroundColor: YakkuPalette.primary,
                    foregroundColor: YakkuPalette.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    busy ? 'Checking…' : 'Check payment status',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  const _PaymentHistoryTile({
    required this.item,
    required this.busy,
    this.onCheckStatus,
  });

  final PaymentHistoryItem item;
  final bool busy;
  final VoidCallback? onCheckStatus;

  @override
  Widget build(BuildContext context) {
    final type = PaymentStatusLabels.purchaseType(item.purchaseType);
    final title = item.planName.isNotEmpty ? item.planName : type;
    final purchasedOn = PaymentStatusLabels.formatDate(
      item.paidAt ?? item.createdAt,
    );
    final showExpiry = item.purchaseType == PaymentPurchaseTypes.userPlan &&
        PaymentOrderStatuses.isFulfilled(item.status);
    final look = _PaymentTileLook.forItem(item);

    return Material(
      color: look.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: look.border, width: 1.4),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: look.iconWash,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: FaIcon(
                    look.icon,
                    size: 16,
                    color: look.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: YakkuPalette.Ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          color: look.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.formattedAmount,
                  style: TextStyle(
                    color: look.amountColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: YakkuPalette.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: YakkuPalette.roseBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Purchased $purchasedOn',
                          style: const TextStyle(
                            color: YakkuPalette.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _PaymentStatusChip(status: item.status),
                    ],
                  ),
                  if (showExpiry) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Expires ${PaymentStatusLabels.formatDate(item.expiresAt)}',
                        style: const TextStyle(
                          color: YakkuPalette.Ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onCheckStatus != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: Semantics(
                  button: true,
                  enabled: !busy,
                  label: busy ? 'Checking payment status' : 'Check status',
                  child: OutlinedButton(
                    onPressed: busy ? null : onCheckStatus,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: YakkuPalette.Raspberry,
                      disabledForegroundColor: YakkuPalette.disabledMauve,
                      side: BorderSide(
                        color: busy
                            ? YakkuPalette.disabledMauve
                            : YakkuPalette.Raspberry,
                        width: 1.5,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      busy ? 'Checking…' : 'Check status',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Soft plan tint + icon, matching Yakku plans sheet fills.
class _PaymentTileLook {
  const _PaymentTileLook({
    required this.fill,
    required this.border,
    required this.iconWash,
    required this.accent,
    required this.amountColor,
    required this.icon,
  });

  final Color fill;
  final Color border;
  final Color iconWash;
  final Color accent;
  final Color amountColor;
  final FaIconData icon;

  static _PaymentTileLook forItem(PaymentHistoryItem item) {
    final code = item.planCode.toLowerCase();
    if (code.contains('love')) {
      return const _PaymentTileLook(
        fill: YakkuPalette.butter,
        border: YakkuPalette.Gold,
        iconWash: YakkuPalette.white,
        accent: YakkuPalette.goldInk,
        amountColor: YakkuPalette.Ink,
        icon: FontAwesomeIcons.heart,
      );
    }
    if (code.contains('lite')) {
      return const _PaymentTileLook(
        fill: YakkuPalette.pillPink,
        border: YakkuPalette.Blush,
        iconWash: YakkuPalette.white,
        accent: YakkuPalette.Raspberry,
        amountColor: YakkuPalette.Raspberry,
        icon: FontAwesomeIcons.ticket,
      );
    }
    if (item.purchaseType == PaymentPurchaseTypes.cardUnlock ||
        code.contains('card') ||
        code.contains('this_card')) {
      return const _PaymentTileLook(
        fill: YakkuPalette.pinkMist,
        border: YakkuPalette.roseBorder,
        iconWash: YakkuPalette.white,
        accent: YakkuPalette.Raspberry,
        amountColor: YakkuPalette.Raspberry,
        icon: FontAwesomeIcons.unlockKeyhole,
      );
    }
    return const _PaymentTileLook(
      fill: YakkuPalette.white,
      border: YakkuPalette.roseBorder,
      iconWash: YakkuPalette.greyBlush,
      accent: YakkuPalette.Raspberry,
      amountColor: YakkuPalette.Ink,
      icon: FontAwesomeIcons.receipt,
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  const _PaymentStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final style = PaymentStatusLabels.statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        PaymentStatusLabels.status(status).toUpperCase(),
        style: TextStyle(
          color: style.foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.35,
          height: 1.1,
        ),
      ),
    );
  }
}
