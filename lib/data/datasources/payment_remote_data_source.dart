import 'package:yakku/data/models/payments/payment_models.dart';

/// Authenticated payment APIs under `/api/v1/payments`.
///
/// Prices, eligibility, verification, and entitlements stay on the backend.
abstract interface class PaymentRemoteDataSource {
  /// `POST /api/v1/payments/orders` — create internal + Razorpay order.
  Future<CreatePaymentOrderResponse> createOrder(
    CreatePaymentOrderRequest request,
  );

  /// `POST /api/v1/payments/verify` — verify Checkout callback and fulfill.
  Future<VerifyPaymentResponse> verify(VerifyPaymentRequest request);

  /// `GET /api/v1/payments/orders/{orderId}` — owner-scoped status.
  Future<PaymentOrderStatus> getOrder(String orderId);

  /// `GET /api/v1/payments/history` — caller's orders, newest first.
  Future<PaymentHistoryPage> getHistory({int page = 1, int pageSize = 10});
}
