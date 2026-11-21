import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Thin wrapper around the official Razorpay Flutter SDK so unit tests can
/// simulate checkout callbacks without platform channels.
abstract interface class RazorpayGateway {
  void on(String event, Function handler);

  void open(Map<String, dynamic> options);

  void clear();
}

/// Production gateway backed by [Razorpay].
class SdkRazorpayGateway implements RazorpayGateway {
  SdkRazorpayGateway({Razorpay? razorpay}) : _razorpay = razorpay ?? Razorpay();

  final Razorpay _razorpay;

  @override
  void on(String event, Function handler) => _razorpay.on(event, handler);

  @override
  void open(Map<String, dynamic> options) => _razorpay.open(options);

  @override
  void clear() => _razorpay.clear();
}

/// Event names used by [RazorpayGateway.on] (mirrors [Razorpay] constants).
abstract final class RazorpayGatewayEvents {
  static const paymentSuccess = Razorpay.EVENT_PAYMENT_SUCCESS;
  static const paymentError = Razorpay.EVENT_PAYMENT_ERROR;
  static const externalWallet = Razorpay.EVENT_EXTERNAL_WALLET;
}

/// SDK error codes used for cancellation detection.
abstract final class RazorpayGatewayErrorCodes {
  static const paymentCancelled = Razorpay.PAYMENT_CANCELLED;
  static const networkError = Razorpay.NETWORK_ERROR;
  static const invalidOptions = Razorpay.INVALID_OPTIONS;
  static const tlsError = Razorpay.TLS_ERROR;
  static const incompatiblePlugin = Razorpay.INCOMPATIBLE_PLUGIN;
  static const unknownError = Razorpay.UNKNOWN_ERROR;
}
