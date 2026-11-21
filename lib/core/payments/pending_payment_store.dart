import 'dart:convert';

import 'package:yakku/core/storage/secure_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';

/// Local record of a checkout that may still need backend verification.
///
/// Used when the Razorpay callback arrives but the verify call fails (network),
/// or when the user closes Checkout and status must be reconciled on resume.
/// Never treats this as proof of entitlement — only a recovery hint.
class PendingPayment {
  const PendingPayment({
    required this.orderId,
    required this.razorpayOrderId,
    required this.planCode,
    required this.planName,
    required this.purchaseType,
    required this.amountInPaise,
    required this.currency,
    required this.savedAt,
    this.contentType,
    this.contentId,
    this.razorpayPaymentId,
    this.razorpaySignature,
  });

  final String orderId;
  final String razorpayOrderId;
  final String planCode;
  final String planName;
  final String purchaseType;
  final int amountInPaise;
  final String currency;
  final DateTime savedAt;
  final String? contentType;
  final String? contentId;

  /// Present after a success callback, before / if verify completed.
  final String? razorpayPaymentId;
  final String? razorpaySignature;

  bool get hasVerifyPayload =>
      razorpayPaymentId != null &&
      razorpayPaymentId!.isNotEmpty &&
      razorpaySignature != null &&
      razorpaySignature!.isNotEmpty;

  PendingPayment copyWith({
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) {
    return PendingPayment(
      orderId: orderId,
      razorpayOrderId: razorpayOrderId,
      planCode: planCode,
      planName: planName,
      purchaseType: purchaseType,
      amountInPaise: amountInPaise,
      currency: currency,
      savedAt: savedAt,
      contentType: contentType,
      contentId: contentId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      razorpaySignature: razorpaySignature ?? this.razorpaySignature,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'orderId': orderId,
      'razorpayOrderId': razorpayOrderId,
      'planCode': planCode,
      'planName': planName,
      'purchaseType': purchaseType,
      'amountInPaise': amountInPaise,
      'currency': currency,
      'savedAt': savedAt.toUtc().toIso8601String(),
      if (contentType != null) 'contentType': contentType,
      if (contentId != null) 'contentId': contentId,
      if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
      if (razorpaySignature != null) 'razorpaySignature': razorpaySignature,
    };
  }

  factory PendingPayment.fromJson(Map<String, dynamic> json) {
    return PendingPayment(
      orderId: json['orderId']?.toString() ?? '',
      razorpayOrderId: json['razorpayOrderId'] as String? ?? '',
      planCode: json['planCode'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      purchaseType: json['purchaseType'] as String? ?? '',
      amountInPaise: (json['amountInPaise'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      contentType: json['contentType'] as String?,
      contentId: json['contentId']?.toString(),
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      razorpaySignature: json['razorpaySignature'] as String?,
    );
  }
}

class PendingPaymentStore {
  PendingPaymentStore({required this._secureStorage});

  final SecureStorageService _secureStorage;

  Future<PendingPayment?> read() async {
    final raw = await _secureStorage.read(StorageKeys.pendingPaymentOrder);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final pending = PendingPayment.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (pending.orderId.isEmpty) return null;
      return pending;
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> save(PendingPayment pending) async {
    await _secureStorage.update(
      StorageKeys.pendingPaymentOrder,
      jsonEncode(pending.toJson()),
    );
  }

  Future<void> clear() async {
    await _secureStorage.delete(StorageKeys.pendingPaymentOrder);
  }

  /// Clears only when the stored order matches [orderId].
  Future<void> clearIfOrder(String orderId) async {
    final current = await read();
    if (current == null) return;
    if (current.orderId == orderId) await clear();
  }
}
