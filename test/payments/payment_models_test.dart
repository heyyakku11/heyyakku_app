import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/payments/payment_error_codes.dart';
import 'package:yakku/data/models/payments/payment_models.dart';

void main() {
  group('newPaymentIdempotencyKey', () {
    test('returns a non-empty UUID-shaped key accepted by the backend pattern', () {
      final key = newPaymentIdempotencyKey();
      expect(key, isNotEmpty);
      expect(key.length, lessThanOrEqualTo(128));
      expect(RegExp(r'^[A-Za-z0-9._\-:/]+$').hasMatch(key), isTrue);
    });
  });

  group('CreatePaymentOrderRequest', () {
    test('omits card fields for plan purchases', () {
      final json = const CreatePaymentOrderRequest(
        planId: 'plan-lite',
        idempotencyKey: 'abc-123',
      ).toJson();
      expect(json, {
        'planId': 'plan-lite',
        'idempotencyKey': 'abc-123',
      });
    });

    test('includes content fields for this_card', () {
      final json = const CreatePaymentOrderRequest(
        planId: 'plan-card',
        idempotencyKey: 'key-1',
        contentType: 'poll',
        contentId: 'content-1',
      ).toJson();
      expect(json['contentType'], 'poll');
      expect(json['contentId'], 'content-1');
    });
  });

  group('CreatePaymentOrderResponse.fromJson', () {
    test('parses checkout payload without inventing fields', () {
      final response = CreatePaymentOrderResponse.fromJson({
        'orderId': '11111111-1111-1111-1111-111111111111',
        'razorpayOrderId': 'order_ABC',
        'razorpayKeyId': 'rzp_test_key',
        'amountInPaise': 9900,
        'currency': 'INR',
        'purchaseType': 'UserPlan',
        'planCode': 'yakku_lite',
        'planName': 'Yakku Lite',
        'status': 'Pending',
        'expiresAt': '2026-11-19T12:00:00Z',
      });

      expect(response.orderId, '11111111-1111-1111-1111-111111111111');
      expect(response.razorpayOrderId, 'order_ABC');
      expect(response.razorpayKeyId, 'rzp_test_key');
      expect(response.amountInPaise, 9900);
      expect(response.planCode, 'yakku_lite');
      expect(response.isCardUnlock, isFalse);
      expect(PaymentOrderStatuses.isOpen(response.status), isTrue);
    });
  });

  group('VerifyPaymentResponse.fromJson', () {
    test('marks paid and alreadyFulfilled', () {
      final response = VerifyPaymentResponse.fromJson({
        'orderId': 'order-1',
        'status': 'Paid',
        'alreadyFulfilled': true,
        'purchaseType': 'UserPlan',
        'planCode': 'yakku_love',
        'planExpiresAt': '2026-12-19T12:00:00Z',
        'razorpayPaymentId': 'pay_XYZ',
      });
      expect(response.isPaid, isTrue);
      expect(response.alreadyFulfilled, isTrue);
      expect(response.planCode, 'yakku_love');
    });
  });

  group('PaymentOrderStatus.fromJson', () {
    test('parses attempts and terminal helpers', () {
      final status = PaymentOrderStatus.fromJson({
        'orderId': 'order-1',
        'status': 'Paid',
        'purchaseType': 'CardUnlock',
        'planCode': 'this_card',
        'planName': 'This card',
        'amountInPaise': 4900,
        'currency': 'INR',
        'razorpayOrderId': 'order_ABC',
        'contentType': 'check',
        'contentId': 'check-1',
        'createdAt': '2026-11-19T10:00:00Z',
        'updatedAt': '2026-11-19T10:05:00Z',
        'paidAt': '2026-11-19T10:05:00Z',
        'expiresAt': '2026-11-19T11:00:00Z',
        'attempts': [
          {
            'attemptId': 'attempt-1',
            'razorpayPaymentId': 'pay_1',
            'status': 'Captured',
            'razorpayStatus': 'captured',
            'paymentMethod': 'upi',
            'createdAt': '2026-11-19T10:01:00Z',
            'capturedAt': '2026-11-19T10:05:00Z',
          },
        ],
      });

      expect(status.isPaid, isTrue);
      expect(status.isTerminal, isTrue);
      expect(status.attempts, hasLength(1));
      expect(status.attempts.first.paymentMethod, 'upi');
      expect(status.contentType, 'check');
    });
  });

  group('PaymentHistoryPage.fromApi', () {
    test('reads page meta from ApiResponse.meta', () {
      final page = PaymentHistoryPage.fromApi(
        items: [
          PaymentHistoryItem.fromJson({
            'orderId': 'order-1',
            'status': 'Paid',
            'purchaseType': 'UserPlan',
            'planCode': 'yakku_lite',
            'planName': 'Yakku Lite',
            'amountInPaise': 9900,
            'currency': 'INR',
            'createdAt': '2026-11-19T10:00:00Z',
            'paidAt': '2026-11-19T10:05:00Z',
            'expiresAt': '2026-11-19T11:00:00Z',
          }),
        ],
        meta: {
          'page': 1,
          'pageSize': 10,
          'totalCount': 12,
          'totalPages': 2,
        },
      );

      expect(page.hasMore, isTrue);
      expect(page.totalCount, 12);
      expect(page.items.first.formattedAmount, '₹99');
    });
  });

  group('PaymentErrorCodes', () {
    test('maps known purchase rejections', () {
      expect(
        PaymentErrorCodes.isPurchaseRejected(
          PaymentErrorCodes.planAlreadyActive,
        ),
        isTrue,
      );
      expect(
        PaymentErrorCodes.isPurchaseRejected(
          PaymentErrorCodes.paymentGatewayError,
        ),
        isFalse,
      );
      expect(
        PaymentErrorCodes.userMessage(
          PaymentErrorCodes.planDowngradeNotAllowed,
        ),
        contains('Love'),
      );
    });
  });
}
