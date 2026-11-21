import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:yakku/core/payments/checkout_prefill.dart';
import 'package:yakku/core/payments/razorpay_gateway.dart';
import 'package:yakku/data/models/payments/payment_models.dart';

/// Options for opening Razorpay Checkout from a backend-created order.
///
/// Never includes a Key Secret — only the public Key ID from the backend.
/// Amount, currency, key, and order id must come from the backend order.
class RazorpayCheckoutOptions {
  const RazorpayCheckoutOptions({
    required this.razorpayKeyId,
    required this.razorpayOrderId,
    required this.amountInPaise,
    required this.currency,
    required this.description,
    this.name = 'Yakku',
    this.contact,
    this.email,
    this.internalOrderId,
    this.planCode,
    this.themeColor = '#D02E62',
  });

  factory RazorpayCheckoutOptions.fromOrder(
    CreatePaymentOrderResponse order, {
    String? contact,
    String? email,
    String name = 'Yakku',
  }) {
    return RazorpayCheckoutOptions(
      razorpayKeyId: order.razorpayKeyId,
      razorpayOrderId: order.razorpayOrderId,
      amountInPaise: order.amountInPaise,
      currency: order.currency,
      description: order.planName,
      name: name,
      contact: CheckoutPrefill.contact(contact),
      email: CheckoutPrefill.email(email),
      internalOrderId: order.orderId,
      planCode: order.planCode,
    );
  }

  final String razorpayKeyId;
  final String razorpayOrderId;
  final int amountInPaise;
  final String currency;
  final String name;
  final String description;
  final String? contact;
  final String? email;

  /// Yakku internal order id (not sent to Razorpay; used for local correlation).
  final String? internalOrderId;

  /// Included in Razorpay `notes` for support / dashboard correlation.
  final String? planCode;
  final String themeColor;

  Map<String, dynamic> toSdkOptions() {
    final currencyCode = currency.trim().toUpperCase();
    final prefillContact = CheckoutPrefill.contact(contact);
    final prefillEmail = CheckoutPrefill.email(email);
    final notes = <String, String>{
      if (internalOrderId != null && internalOrderId!.isNotEmpty)
        'yakku_order_id': internalOrderId!,
      if (planCode != null && planCode!.isNotEmpty) 'plan_code': planCode!,
    };

    return <String, dynamic>{
      'key': razorpayKeyId.trim(),
      'amount': amountInPaise,
      'currency': currencyCode.isEmpty ? 'INR' : currencyCode,
      'name': name,
      'description': description,
      'order_id': razorpayOrderId.trim(),
      'theme': <String, dynamic>{'color': themeColor},
      // Let Razorpay show all methods enabled on the Key / account.
      'method': <String, dynamic>{
        'netbanking': true,
        'card': true,
        'upi': true,
        'wallet': true,
      },
      'retry': <String, dynamic>{'enabled': true, 'max_count': 1},
      if (notes.isNotEmpty) 'notes': notes,
      if (prefillContact != null || prefillEmail != null)
        'prefill': <String, dynamic>{
          if (prefillContact != null) 'contact': prefillContact,
          if (prefillEmail != null) 'email': prefillEmail,
        },
    };
  }
}

/// Result of a Checkout session. Success is **not** entitlement — verify on
/// the backend before granting access.
sealed class RazorpayCheckoutResult {
  const RazorpayCheckoutResult();
}

class RazorpayCheckoutSuccess extends RazorpayCheckoutResult {
  const RazorpayCheckoutSuccess({
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
    this.internalOrderId,
  });

  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;
  final String? internalOrderId;
}

class RazorpayCheckoutFailure extends RazorpayCheckoutResult {
  const RazorpayCheckoutFailure({
    required this.code,
    required this.message,
    required this.isCancelled,
    this.internalOrderId,
  });

  final int? code;
  final String message;
  final bool isCancelled;
  final String? internalOrderId;
}

/// Thrown when Checkout cannot be opened (already open, missing fields, SDK).
class RazorpayCheckoutException implements Exception {
  const RazorpayCheckoutException(this.message);

  final String message;

  @override
  String toString() => 'RazorpayCheckoutException: $message';
}

/// Owns one Razorpay SDK instance, enforces a single checkout session, and
/// maps SDK callbacks into typed [RazorpayCheckoutResult]s.
///
/// Dispose from the app root. Do not create a second instance while one is live.
class RazorpayCheckoutService extends ChangeNotifier {
  RazorpayCheckoutService({RazorpayGateway? gateway})
    : _gateway = gateway ?? SdkRazorpayGateway() {
    _gateway.on(RazorpayGatewayEvents.paymentSuccess, _onSuccess);
    _gateway.on(RazorpayGatewayEvents.paymentError, _onError);
    _gateway.on(RazorpayGatewayEvents.externalWallet, _onExternalWallet);
  }

  final RazorpayGateway _gateway;

  Completer<RazorpayCheckoutResult>? _session;
  String? _activeInternalOrderId;
  String? _activeRazorpayOrderId;
  bool _opening = false;
  bool _disposed = false;
  String? _lastExternalWallet;
  bool _callbackHandled = false;

  /// True while [open] is preparing / launching the native Checkout UI.
  bool get isOpening => _opening;

  /// True while a Checkout session is open (including [isOpening]).
  bool get isSessionActive => _session != null && !(_session!.isCompleted);

  /// Last external wallet name reported by the SDK for the active session.
  String? get lastExternalWallet => _lastExternalWallet;

  /// Opens Razorpay Checkout for a backend-created order.
  ///
  /// Completes when the SDK reports success or failure/cancellation.
  /// External-wallet selection does not complete the session by itself.
  ///
  /// Throws [RazorpayCheckoutException] if a session is already active, the
  /// service was disposed, or required checkout fields are missing.
  Future<RazorpayCheckoutResult> open(RazorpayCheckoutOptions options) async {
    if (_disposed) {
      throw const RazorpayCheckoutException('Checkout service was disposed.');
    }
    if (isSessionActive || _opening) {
      throw const RazorpayCheckoutException(
        'A payment checkout is already in progress.',
      );
    }
    _validate(options);

    final completer = Completer<RazorpayCheckoutResult>();
    _session = completer;
    _activeInternalOrderId = options.internalOrderId;
    _activeRazorpayOrderId = options.razorpayOrderId;
    _lastExternalWallet = null;
    _callbackHandled = false;
    _opening = true;
    notifyListeners();

    try {
      _gateway.open(options.toSdkOptions());
    } catch (error, stack) {
      _opening = false;
      _session = null;
      _activeInternalOrderId = null;
      _activeRazorpayOrderId = null;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[Payments] Razorpay open failed: $error\n$stack');
      }
      throw RazorpayCheckoutException(
        'Could not open payment checkout. Please try again.',
      );
    }

    _opening = false;
    notifyListeners();
    return completer.future;
  }

  /// Marks an unresolved session as cancelled without opening a new one.
  ///
  /// Used when the app resumes and Checkout was abandoned without a callback.
  /// Prefer querying backend order status after this (Phase 8).
  void markInterrupted({String message = 'Payment was interrupted.'}) {
    if (!isSessionActive) return;
    _complete(
      RazorpayCheckoutFailure(
        code: RazorpayGatewayErrorCodes.paymentCancelled,
        message: message,
        isCancelled: true,
        internalOrderId: _activeInternalOrderId,
      ),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (isSessionActive) {
      _complete(
        RazorpayCheckoutFailure(
          code: RazorpayGatewayErrorCodes.unknownError,
          message: 'Payment checkout was closed.',
          isCancelled: true,
          internalOrderId: _activeInternalOrderId,
        ),
      );
    }
    try {
      _gateway.clear();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Payments] Razorpay clear failed: $error');
      }
    }
    super.dispose();
  }

  void _onSuccess(PaymentSuccessResponse response) {
    if (_callbackHandled || _disposed) return;
    final paymentId = response.paymentId?.trim() ?? '';
    final orderId = response.orderId?.trim() ?? _activeRazorpayOrderId ?? '';
    final signature = response.signature?.trim() ?? '';
    if (paymentId.isEmpty || orderId.isEmpty || signature.isEmpty) {
      _complete(
        RazorpayCheckoutFailure(
          code: RazorpayGatewayErrorCodes.invalidOptions,
          message:
              'Payment details were incomplete. Check payment status before retrying.',
          isCancelled: false,
          internalOrderId: _activeInternalOrderId,
        ),
      );
      return;
    }
    _complete(
      RazorpayCheckoutSuccess(
        razorpayPaymentId: paymentId,
        razorpayOrderId: orderId,
        razorpaySignature: signature,
        internalOrderId: _activeInternalOrderId,
      ),
    );
  }

  void _onError(PaymentFailureResponse response) {
    if (_callbackHandled || _disposed) return;
    final code = response.code;
    final cancelled = code == RazorpayGatewayErrorCodes.paymentCancelled;
    final message = (response.message?.trim().isNotEmpty ?? false)
        ? response.message!.trim()
        : (cancelled
              ? 'Payment was cancelled.'
              : 'Payment failed. Please try again.');
    _complete(
      RazorpayCheckoutFailure(
        code: code,
        message: message,
        isCancelled: cancelled,
        internalOrderId: _activeInternalOrderId,
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (_disposed || !isSessionActive) return;
    _lastExternalWallet = response.walletName;
    notifyListeners();
  }

  void _complete(RazorpayCheckoutResult result) {
    if (_callbackHandled) return;
    final session = _session;
    if (session == null || session.isCompleted) return;
    _callbackHandled = true;
    _opening = false;
    _session = null;
    _activeInternalOrderId = null;
    _activeRazorpayOrderId = null;
    session.complete(result);
    notifyListeners();
  }

  void _validate(RazorpayCheckoutOptions options) {
    if (options.razorpayKeyId.trim().isEmpty) {
      throw const RazorpayCheckoutException('Missing Razorpay key id.');
    }
    if (options.razorpayOrderId.trim().isEmpty) {
      throw const RazorpayCheckoutException('Missing Razorpay order id.');
    }
    if (options.amountInPaise <= 0) {
      throw const RazorpayCheckoutException('Invalid payment amount.');
    }
    if (options.currency.trim().isEmpty) {
      throw const RazorpayCheckoutException('Missing payment currency.');
    }
  }
}
