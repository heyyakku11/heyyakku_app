import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';

/// Backend wire values: unknown | granted | denied
abstract final class NotificationPermissionValues {
  static const unknown = 'unknown';
  static const granted = 'granted';
  static const denied = 'denied';
}

class NotificationPermissionService {
  NotificationPermissionService({
    PreferenceStorageService? storage,
    FirebaseMessaging? messaging,
  }) : _storage = storage ?? PreferenceStorageService(),
       _messaging = messaging ?? FirebaseMessaging.instance;

  final PreferenceStorageService _storage;
  final FirebaseMessaging _messaging;

  Future<bool> hasAsked() async {
    return await _storage.readBool(StorageKeys.notificationPermissionAsked) ??
        false;
  }

  Future<bool> isNotificationAllowed() async {
    return await _storage.readBool(StorageKeys.isNotificationAllowed) ?? false;
  }

  Future<void> markAsked({required bool allowed}) async {
    await _storage.updateBool(StorageKeys.notificationPermissionAsked, true);
    await _storage.updateBool(StorageKeys.isNotificationAllowed, allowed);
  }

  /// Requests OS/FCM notification permission. Does not show the in-app dialog.
  Future<String> requestOsPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return mapAuthorizationStatus(settings.authorizationStatus);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FCM] requestPermission failed: $error');
      }
      return NotificationPermissionValues.unknown;
    }
  }

  Future<String> currentPermissionStatus() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return mapAuthorizationStatus(settings.authorizationStatus);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FCM] getNotificationSettings failed: $error');
      }
      final allowed = await isNotificationAllowed();
      return allowed
          ? NotificationPermissionValues.granted
          : NotificationPermissionValues.denied;
    }
  }

  static String mapAuthorizationStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return NotificationPermissionValues.granted;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.deniedPermanently:
        return NotificationPermissionValues.denied;
      case AuthorizationStatus.notDetermined:
        return NotificationPermissionValues.unknown;
    }
  }
}
