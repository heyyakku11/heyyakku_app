import 'package:flutter/material.dart';
import 'package:yakku/core/payments/payment_confirm_result.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// Kind of terminal / intermediate payment surface after Checkout / verify.
enum PaymentOutcomeKind { success, failure, pending }

/// Non-dismissible progress overlay used while opening Checkout or confirming.
///
/// Uses an [OverlayEntry] so dismiss never pops the wrong Navigator route when
/// work finishes before a dialog route would have been pushed.
///
/// Returns a dismiss callback that is safe to call more than once.
VoidCallback showPaymentProgressDialog(
  BuildContext context, {
  required String message,
}) {
  var dismissed = false;
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) {
      return Stack(
        children: [
          const ModalBarrier(dismissible: false, color: Color(0x66000000)),
          Center(
            child: Semantics(
              liveRegion: true,
              label: message,
              child: Material(
                color: YakkuPalette.cream,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 22,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.6),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: YakkuPalette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  overlay.insert(entry);

  void dismiss() {
    if (dismissed) return;
    dismissed = true;
    entry.remove();
  }

  return dismiss;
}

/// Maps a confirm result to the outcome kind shown to the user.
PaymentOutcomeKind? outcomeKindForConfirm(PaymentConfirmResult result) {
  return switch (result) {
    PaymentConfirmFulfilled() => PaymentOutcomeKind.success,
    PaymentConfirmPending() => PaymentOutcomeKind.pending,
    PaymentConfirmFailed() => PaymentOutcomeKind.failure,
  };
}

/// Modal outcome after backend confirmation (or failure / still processing).
///
/// Returns `true` when the user chose [retryLabel].
Future<bool> showPaymentOutcomeDialog(
  BuildContext context, {
  required PaymentOutcomeKind kind,
  required String title,
  required String message,
  String primaryLabel = 'OK',
  String? retryLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: kind != PaymentOutcomeKind.success,
    builder: (dialogContext) {
      final (icon, tint) = switch (kind) {
        PaymentOutcomeKind.success => (
          Icons.check_circle_rounded,
          YakkuPalette.forestGreen,
        ),
        PaymentOutcomeKind.pending => (
          Icons.hourglass_top_rounded,
          YakkuPalette.textSecondary,
        ),
        PaymentOutcomeKind.failure => (
          Icons.error_outline_rounded,
          YakkuPalette.primary,
        ),
      };

      return AlertDialog(
        backgroundColor: YakkuPalette.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(icon, color: tint, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: YakkuPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: YakkuPalette.textSecondary,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (retryLabel != null)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(retryLabel),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: FilledButton.styleFrom(
              backgroundColor: YakkuPalette.primary,
              foregroundColor: YakkuPalette.white,
              shape: const StadiumBorder(),
            ),
            child: Text(
              primaryLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Shows the right outcome dialog for a [PaymentConfirmResult].
///
/// Pending offers a retry action by default. Returns whether retry was chosen.
Future<bool> presentPaymentConfirmOutcome(
  BuildContext context,
  PaymentConfirmResult result, {
  bool offerPendingRetry = true,
}) {
  final kind = outcomeKindForConfirm(result)!;
  final (title, message, retry) = switch (result) {
    PaymentConfirmFulfilled(:final alreadyFulfilled) => (
      alreadyFulfilled ? 'Already unlocked' : 'Payment successful',
      alreadyFulfilled
          ? 'You already have this purchase. Your access is up to date.'
          : 'Your purchase is confirmed. Enjoy Yakku.',
      null,
    ),
    PaymentConfirmPending(:final message) => (
      'Payment processing',
      message,
      offerPendingRetry ? 'Check again' : null,
    ),
    PaymentConfirmFailed(:final message) => (
      'Payment not confirmed',
      message,
      null,
    ),
  };

  return showPaymentOutcomeDialog(
    context,
    kind: kind,
    title: title,
    message: message,
    primaryLabel: kind == PaymentOutcomeKind.pending ? 'Close' : 'OK',
    retryLabel: retry,
  );
}
