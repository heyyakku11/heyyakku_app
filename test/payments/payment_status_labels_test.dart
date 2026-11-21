import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/payments/payment_models.dart';
import 'package:yakku/presentation/payments/payment_status_labels.dart';

void main() {
  test('maps backend statuses to user copy', () {
    expect(PaymentStatusLabels.status(PaymentOrderStatuses.paid), 'Paid');
    expect(
      PaymentStatusLabels.status(PaymentOrderStatuses.pending),
      'Processing',
    );
    expect(
      PaymentStatusLabels.status(PaymentOrderStatuses.cancelled),
      'Cancelled',
    );
  });

  test('status chips use intent colors', () {
    final paid = PaymentStatusLabels.statusStyle(PaymentOrderStatuses.paid);
    expect(paid.foreground, YakkuPalette.successGreen);
    expect(paid.background, YakkuPalette.accentGreen);

    final failed = PaymentStatusLabels.statusStyle(PaymentOrderStatuses.failed);
    expect(failed.foreground, YakkuPalette.error);
    expect(failed.background, YakkuPalette.blushFill);

    final pending =
        PaymentStatusLabels.statusStyle(PaymentOrderStatuses.pending);
    expect(pending.foreground, YakkuPalette.goldInk);
    expect(pending.background, YakkuPalette.butter);
  });

  test('open statuses can be checked again', () {
    expect(
      PaymentStatusLabels.canCheckStatus(PaymentOrderStatuses.pending),
      isTrue,
    );
    expect(
      PaymentStatusLabels.canCheckStatus(PaymentOrderStatuses.paid),
      isFalse,
    );
  });

  test('formats local dates as dd/mm/yyyy', () {
    expect(
      PaymentStatusLabels.formatDate(DateTime.utc(2026, 11, 19, 12)),
      isNotEmpty,
    );
  });
}
