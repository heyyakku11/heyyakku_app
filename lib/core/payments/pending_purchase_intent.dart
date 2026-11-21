import 'dart:convert';

import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';

/// What the user wanted to buy before authentication interrupted checkout.
///
/// Not proof of payment or entitlement — only a resume hint after sign-in.
/// Backend purchase rules are revalidated when plans / orders load again.
class PendingPurchaseIntent {
  const PendingPurchaseIntent({
    required this.planId,
    required this.planCode,
    required this.planName,
    required this.savedAt,
    this.contentType,
    this.contentId,
  });

  final String planId;
  final String planCode;
  final String planName;
  final DateTime savedAt;
  final String? contentType;
  final String? contentId;

  static const ttl = Duration(hours: 24);

  bool get isExpired => DateTime.now().toUtc().difference(savedAt.toUtc()) > ttl;

  bool get hasCardContext =>
      contentType != null &&
      contentType!.isNotEmpty &&
      contentId != null &&
      contentId!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'planId': planId,
      'planCode': planCode,
      'planName': planName,
      'savedAt': savedAt.toUtc().toIso8601String(),
      if (contentType != null) 'contentType': contentType,
      if (contentId != null) 'contentId': contentId,
    };
  }

  factory PendingPurchaseIntent.fromJson(Map<String, dynamic> json) {
    return PendingPurchaseIntent(
      planId: json['planId']?.toString() ?? '',
      planCode: json['planCode'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      contentType: json['contentType'] as String?,
      contentId: json['contentId']?.toString(),
    );
  }
}

class PendingPurchaseStore {
  PendingPurchaseStore({required this._storage});

  final PreferenceStorageService _storage;

  Future<PendingPurchaseIntent?> read() async {
    final raw = await _storage.read(StorageKeys.pendingPurchaseIntent);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final intent = PendingPurchaseIntent.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (intent.planId.isEmpty || intent.planCode.isEmpty) return null;
      if (intent.isExpired) {
        await clear();
        return null;
      }
      return intent;
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> save(PendingPurchaseIntent intent) async {
    await _storage.update(
      StorageKeys.pendingPurchaseIntent,
      jsonEncode(intent.toJson()),
    );
  }

  Future<void> clear() async {
    await _storage.delete(StorageKeys.pendingPurchaseIntent);
  }
}
