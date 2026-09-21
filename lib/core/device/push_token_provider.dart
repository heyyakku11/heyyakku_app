import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Obtains the current FCM token managed by Firebase (never generates one manually).
class PushTokenProvider {
  PushTokenProvider({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (kDebugMode && token != null) {
        debugPrint('[FCM] Token available (len=${token.length})');
      }
      return token;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FCM] getToken failed: $error');
      }
      return null;
    }
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
