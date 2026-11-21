import 'package:uuid/uuid.dart';

/// Creates a client idempotency key accepted by the backend
/// (`^[A-Za-z0-9._\-:/]+$`, max 128).
String newPaymentIdempotencyKey() => const Uuid().v4();

/// Internal payment order lifecycle (`PaymentOrderStatus` enum names).
abstract final class PaymentOrderStatuses {
  static const created = 'Created';
  static const pending = 'Pending';
  static const paid = 'Paid';
  static const failed = 'Failed';
  static const cancelled = 'Cancelled';
  static const expired = 'Expired';

  static bool isTerminal(String status) => switch (status) {
        paid || failed || cancelled || expired => true,
        _ => false,
      };

  static bool isOpen(String status) =>
      status == created || status == pending;

  static bool isFulfilled(String status) => status == paid;
}

/// What was purchased (`PaymentPurchaseType` enum names).
abstract final class PaymentPurchaseTypes {
  static const userPlan = 'UserPlan';
  static const cardUnlock = 'CardUnlock';
}

/// `POST /api/v1/payments/orders` body. Never includes amount — backend prices.
class CreatePaymentOrderRequest {
  const CreatePaymentOrderRequest({
    required this.planId,
    required this.idempotencyKey,
    this.contentType,
    this.contentId,
  });

  final String planId;
  final String idempotencyKey;

  /// `poll` or `check` when buying permanent access to one card (`this_card`).
  final String? contentType;
  final String? contentId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'planId': planId,
      'idempotencyKey': idempotencyKey,
      if (contentType != null) 'contentType': contentType,
      if (contentId != null) 'contentId': contentId,
    };
  }
}

/// Checkout payload from `POST /api/v1/payments/orders`.
///
/// Contains the public Razorpay Key ID only — never a secret.
class CreatePaymentOrderResponse {
  const CreatePaymentOrderResponse({
    required this.orderId,
    required this.razorpayOrderId,
    required this.razorpayKeyId,
    required this.amountInPaise,
    required this.currency,
    required this.purchaseType,
    required this.planCode,
    required this.planName,
    required this.status,
    required this.expiresAt,
    this.contentType,
    this.contentId,
  });

  final String orderId;
  final String razorpayOrderId;
  final String razorpayKeyId;
  final int amountInPaise;
  final String currency;
  final String purchaseType;
  final String planCode;
  final String planName;
  final String status;
  final DateTime expiresAt;
  final String? contentType;
  final String? contentId;

  bool get isCardUnlock => purchaseType == PaymentPurchaseTypes.cardUnlock;

  factory CreatePaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreatePaymentOrderResponse(
      orderId: json['orderId']?.toString() ?? '',
      razorpayOrderId: json['razorpayOrderId'] as String? ?? '',
      razorpayKeyId: json['razorpayKeyId'] as String? ?? '',
      amountInPaise: (json['amountInPaise'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      purchaseType: json['purchaseType'] as String? ?? '',
      planCode: json['planCode'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      expiresAt: _parseDateRequired(json['expiresAt']),
      contentType: json['contentType'] as String?,
      contentId: json['contentId']?.toString(),
    );
  }
}

/// `POST /api/v1/payments/verify` body from the Razorpay Checkout callback.
class VerifyPaymentRequest {
  const VerifyPaymentRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    };
  }
}

/// Result of backend signature + capture verification / fulfillment.
class VerifyPaymentResponse {
  const VerifyPaymentResponse({
    required this.orderId,
    required this.status,
    required this.alreadyFulfilled,
    required this.purchaseType,
    this.planCode,
    this.planExpiresAt,
    this.contentType,
    this.contentId,
    this.razorpayPaymentId,
  });

  final String orderId;
  final String status;
  final bool alreadyFulfilled;
  final String purchaseType;
  final String? planCode;
  final DateTime? planExpiresAt;
  final String? contentType;
  final String? contentId;
  final String? razorpayPaymentId;

  bool get isPaid => PaymentOrderStatuses.isFulfilled(status);

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) {
    return VerifyPaymentResponse(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      alreadyFulfilled: json['alreadyFulfilled'] as bool? ?? false,
      purchaseType: json['purchaseType'] as String? ?? '',
      planCode: json['planCode'] as String?,
      planExpiresAt: _parseDate(json['planExpiresAt']),
      contentType: json['contentType'] as String?,
      contentId: json['contentId']?.toString(),
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
    );
  }
}

/// One gateway attempt on an order (`GET .../orders/{id}`).
class PaymentAttemptStatus {
  const PaymentAttemptStatus({
    required this.attemptId,
    required this.status,
    required this.createdAt,
    this.razorpayPaymentId,
    this.razorpayStatus,
    this.paymentMethod,
    this.capturedAt,
    this.failedAt,
  });

  final String attemptId;
  final String? razorpayPaymentId;
  final String status;
  final String? razorpayStatus;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? capturedAt;
  final DateTime? failedAt;

  factory PaymentAttemptStatus.fromJson(Map<String, dynamic> json) {
    return PaymentAttemptStatus(
      attemptId: json['attemptId']?.toString() ?? '',
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      status: json['status'] as String? ?? '',
      razorpayStatus: json['razorpayStatus'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      createdAt: _parseDateRequired(json['createdAt']),
      capturedAt: _parseDate(json['capturedAt']),
      failedAt: _parseDate(json['failedAt']),
    );
  }
}

/// Owner-scoped order status from `GET /api/v1/payments/orders/{orderId}`.
class PaymentOrderStatus {
  const PaymentOrderStatus({
    required this.orderId,
    required this.status,
    required this.purchaseType,
    required this.planCode,
    required this.planName,
    required this.amountInPaise,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.razorpayOrderId,
    this.contentType,
    this.contentId,
    this.paidAt,
    this.attempts = const [],
  });

  final String orderId;
  final String status;
  final String purchaseType;
  final String planCode;
  final String planName;
  final int amountInPaise;
  final String currency;
  final String? razorpayOrderId;
  final String? contentType;
  final String? contentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final DateTime expiresAt;
  final List<PaymentAttemptStatus> attempts;

  bool get isPaid => PaymentOrderStatuses.isFulfilled(status);
  bool get isOpen => PaymentOrderStatuses.isOpen(status);
  bool get isTerminal => PaymentOrderStatuses.isTerminal(status);

  factory PaymentOrderStatus.fromJson(Map<String, dynamic> json) {
    final rawAttempts = json['attempts'];
    return PaymentOrderStatus(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      purchaseType: json['purchaseType'] as String? ?? '',
      planCode: json['planCode'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      amountInPaise: (json['amountInPaise'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      razorpayOrderId: json['razorpayOrderId'] as String?,
      contentType: json['contentType'] as String?,
      contentId: json['contentId']?.toString(),
      createdAt: _parseDateRequired(json['createdAt']),
      updatedAt: _parseDateRequired(json['updatedAt']),
      paidAt: _parseDate(json['paidAt']),
      expiresAt: _parseDateRequired(json['expiresAt']),
      attempts: rawAttempts is List
          ? [
              for (final item in rawAttempts)
                if (item is Map)
                  PaymentAttemptStatus.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
            ]
          : const [],
    );
  }
}

/// One row from `GET /api/v1/payments/history`.
class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.orderId,
    required this.status,
    required this.purchaseType,
    required this.planCode,
    required this.planName,
    required this.amountInPaise,
    required this.currency,
    required this.createdAt,
    required this.expiresAt,
    this.razorpayOrderId,
    this.contentType,
    this.contentId,
    this.paidAt,
  });

  final String orderId;
  final String status;
  final String purchaseType;
  final String planCode;
  final String planName;
  final int amountInPaise;
  final String currency;
  final String? razorpayOrderId;
  final String? contentType;
  final String? contentId;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime expiresAt;

  String get formattedAmount {
    final major = (amountInPaise / 100).round();
    if (currency.toUpperCase() == 'INR' || currency.isEmpty) {
      return '₹$major';
    }
    return '$currency $major';
  }

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      purchaseType: json['purchaseType'] as String? ?? '',
      planCode: json['planCode'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      amountInPaise: (json['amountInPaise'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      razorpayOrderId: json['razorpayOrderId'] as String?,
      contentType: json['contentType'] as String?,
      contentId: json['contentId']?.toString(),
      createdAt: _parseDateRequired(json['createdAt']),
      paidAt: _parseDate(json['paidAt']),
      expiresAt: _parseDateRequired(json['expiresAt']),
    );
  }
}

/// Paginated history page (`page` / `pageSize` meta from the API).
class PaymentHistoryPage {
  const PaymentHistoryPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<PaymentHistoryItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory PaymentHistoryPage.fromApi({
    required List<PaymentHistoryItem> items,
    required dynamic meta,
  }) {
    var page = 1;
    var pageSize = items.length;
    var totalCount = items.length;
    var totalPages = 1;
    if (meta is Map) {
      final map = Map<String, dynamic>.from(meta);
      page = (map['page'] as num?)?.toInt() ?? page;
      pageSize = (map['pageSize'] as num?)?.toInt() ?? pageSize;
      totalCount = (map['totalCount'] as num?)?.toInt() ?? totalCount;
      totalPages = (map['totalPages'] as num?)?.toInt() ?? totalPages;
    }
    return PaymentHistoryPage(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: totalPages,
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

DateTime _parseDateRequired(Object? value) {
  return _parseDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
