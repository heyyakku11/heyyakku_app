import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/payments/checkout_prefill.dart';
import 'package:yakku/core/payments/checkout_user_messages.dart';
import 'package:yakku/core/payments/payment_confirm_result.dart';
import 'package:yakku/core/payments/razorpay_checkout_service.dart';
import 'package:yakku/core/payments/razorpay_gateway.dart';
import 'package:yakku/data/models/payments/payment_models.dart';

void main() {
  group('CheckoutPrefill', () {
    test('keeps last 10 digits from +91 numbers', () {
      expect(CheckoutPrefill.contact('+91 98765 43210'), '9876543210');
      expect(CheckoutPrefill.contact('919876543210'), '9876543210');
      expect(CheckoutPrefill.contact('9876543210'), '9876543210');
    });

    test('returns null for short or empty contact', () {
      expect(CheckoutPrefill.contact(null), isNull);
      expect(CheckoutPrefill.contact(''), isNull);
      expect(CheckoutPrefill.contact('12345'), isNull);
    });

    test('trims email', () {
      expect(CheckoutPrefill.email('  a@b.com '), 'a@b.com');
      expect(CheckoutPrefill.email('  '), isNull);
      expect(CheckoutPrefill.email(null), isNull);
    });
  });

  group('RazorpayCheckoutOptions Phase 6', () {
    test('toSdkOptions uses backend fields, notes, methods, normalized prefill',
        () {
      final options = RazorpayCheckoutOptions.fromOrder(
        CreatePaymentOrderResponse(
          orderId: 'ord-99',
          razorpayOrderId: 'order_ABC',
          razorpayKeyId: ' rzp_test_123 ',
          amountInPaise: 9900,
          currency: 'inr',
          purchaseType: PaymentPurchaseTypes.userPlan,
          planCode: 'yakku_lite',
          planName: 'Yakku Lite',
          status: PaymentOrderStatuses.created,
          expiresAt: DateTime.utc(2026, 11, 20),
        ),
        contact: '+919876543210',
      );

      final sdk = options.toSdkOptions();
      expect(sdk['key'], 'rzp_test_123');
      expect(sdk['order_id'], 'order_ABC');
      expect(sdk['amount'], 9900);
      expect(sdk['currency'], 'INR');
      expect(sdk['name'], 'Yakku');
      expect(sdk['description'], 'Yakku Lite');
      expect(sdk['prefill'], {'contact': '9876543210'});
      expect(sdk['notes'], {
        'yakku_order_id': 'ord-99',
        'plan_code': 'yakku_lite',
      });
      expect((sdk['method'] as Map)['upi'], isTrue);
      expect((sdk['method'] as Map)['card'], isTrue);
      expect(sdk.containsKey('key_secret'), isFalse);
    });
  });

  group('CheckoutUserMessages', () {
    test('checkout success stays silent until verify', () {
      expect(
        CheckoutUserMessages.forCheckoutResult(
          const RazorpayCheckoutSuccess(
            razorpayPaymentId: 'pay_1',
            razorpayOrderId: 'order_1',
            razorpaySignature: 'sig',
          ),
        ),
        isNull,
      );
    });

    test('cancel stays silent', () {
      expect(
        CheckoutUserMessages.forCheckoutResult(
          const RazorpayCheckoutFailure(
            code: RazorpayGatewayErrorCodes.paymentCancelled,
            message: 'cancelled',
            isCancelled: true,
          ),
        ),
        isNull,
      );
    });

    test('network failure gets clear copy', () {
      expect(
        CheckoutUserMessages.forCheckoutResult(
          const RazorpayCheckoutFailure(
            code: RazorpayGatewayErrorCodes.networkError,
            message: 'net',
            isCancelled: false,
          ),
        ),
        contains('Network error'),
      );
    });

    test('fulfilled confirm shows success', () {
      expect(
        CheckoutUserMessages.forConfirmResult(
          const PaymentConfirmFulfilled(
            orderId: 'ord-1',
            purchaseType: 'UserPlan',
          ),
        ),
        'Payment successful.',
      );
    });
  });
}
