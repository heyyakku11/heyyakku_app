import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/payments/payment_models.dart';

/// Foreground + soft fill for a payment status chip.
class PaymentStatusStyle {
  const PaymentStatusStyle({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}

/// User-facing copy for payment order statuses (no gateway internals).
abstract final class PaymentStatusLabels {
  static String status(String raw) {
    return switch (raw) {
      PaymentOrderStatuses.paid => 'Paid',
      PaymentOrderStatuses.pending => 'Processing',
      PaymentOrderStatuses.created => 'Started',
      PaymentOrderStatuses.failed => 'Failed',
      PaymentOrderStatuses.cancelled => 'Cancelled',
      PaymentOrderStatuses.expired => 'Expired',
      _ => raw.isEmpty ? 'Unknown' : raw,
    };
  }

  static PaymentStatusStyle statusStyle(String raw) {
    return switch (raw) {
      PaymentOrderStatuses.paid => const PaymentStatusStyle(
          foreground: YakkuPalette.successGreen,
          background: YakkuPalette.accentGreen,
        ),
      PaymentOrderStatuses.failed => const PaymentStatusStyle(
          foreground: YakkuPalette.error,
          background: YakkuPalette.blushFill,
        ),
      PaymentOrderStatuses.cancelled || PaymentOrderStatuses.expired =>
        const PaymentStatusStyle(
          foreground: YakkuPalette.textSecondary,
          background: YakkuPalette.greyBlush,
        ),
      PaymentOrderStatuses.pending || PaymentOrderStatuses.created =>
        const PaymentStatusStyle(
          foreground: YakkuPalette.goldInk,
          background: YakkuPalette.butter,
        ),
      _ => const PaymentStatusStyle(
          foreground: YakkuPalette.textSecondary,
          background: YakkuPalette.greyBlush,
        ),
    };
  }

  static String purchaseType(String raw) {
    return switch (raw) {
      PaymentPurchaseTypes.userPlan => 'Plan',
      PaymentPurchaseTypes.cardUnlock => 'Card unlock',
      _ => 'Purchase',
    };
  }

  static bool canCheckStatus(String status) =>
      PaymentOrderStatuses.isOpen(status);

  static String formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}
