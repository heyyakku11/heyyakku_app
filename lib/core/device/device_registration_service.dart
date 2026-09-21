import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/device/device_metadata_provider.dart';
import 'package:yakku/core/device/installation_id_store.dart';
import 'package:yakku/core/device/notification_permission_service.dart';
import 'package:yakku/core/device/push_token_provider.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/datasources/device_remote_data_source.dart';
import 'package:yakku/data/models/device/register_device_request.dart';

/// Coordinates installation ID, FCM token, metadata, and backend registration.
abstract class DeviceRegistrationService {
  Future<void> initialize();

  /// Fire-and-forget registration; safe to call from UI without awaiting.
  void registerDeviceInBackground();

  Future<void> registerDevice();

  Future<bool> shouldPromptForPermission();

  Future<void> applyAllowChoice();

  Future<void> applySkipChoice();

  void dispose();
}

class DeviceRegistrationServiceImpl implements DeviceRegistrationService {
  DeviceRegistrationServiceImpl({
    required this._authController,
    required this._deviceRemote,
    InstallationIdStore? installationIdStore,
    PushTokenProvider? pushTokenProvider,
    DeviceMetadataProvider? metadataProvider,
    NotificationPermissionService? permissionService,
  }) : _installationIdStore = installationIdStore ?? InstallationIdStore(),
       _pushTokenProvider = pushTokenProvider ?? PushTokenProvider(),
       _metadataProvider = metadataProvider ?? DeviceMetadataProvider(),
       _permissionService =
           permissionService ?? NotificationPermissionService();

  final AuthController _authController;
  final DeviceRemoteDataSource _deviceRemote;
  final InstallationIdStore _installationIdStore;
  final PushTokenProvider _pushTokenProvider;
  final DeviceMetadataProvider _metadataProvider;
  final NotificationPermissionService _permissionService;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  bool _registerInFlight = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _tokenRefreshSubscription ??= _pushTokenProvider.onTokenRefresh.listen((
      newToken,
    ) {
      if (kDebugMode) {
        debugPrint('[FCM] Token refreshed (len=${newToken.length})');
      }
      registerDeviceInBackground();
    });
  }

  @override
  void registerDeviceInBackground() {
    unawaited(_safeRegister());
  }

  @override
  Future<void> registerDevice() => _safeRegister();

  @override
  Future<bool> shouldPromptForPermission() async {
    if (!_authController.isLoggedIn) return false;
    return !(await _permissionService.hasAsked());
  }

  Future<void> _safeRegister() async {
    if (!_authController.isLoggedIn) return;
    if (_registerInFlight) return;

    _registerInFlight = true;
    try {
      await _registerOnce();
    } catch (error) {
      if (kDebugMode) {
        final mapped = DioErrorMapper.map(
          error,
          fallback: 'Device registration failed',
        );
        debugPrint('[Device] Register failed: ${mapped.message}');
      }
    } finally {
      _registerInFlight = false;
    }
  }

  Future<void> _registerOnce() async {
    final installationId = await _installationIdStore.getOrCreate();
    final pushToken = await _pushTokenProvider.getToken();
    final metadata = await _metadataProvider.collect();
    final permission = await _permissionForRegistration();

    final request = RegisterDeviceRequest(
      installationId: installationId,
      pushToken: pushToken,
      platform: metadata.platform,
      deviceModel: metadata.deviceModel,
      osVersion: metadata.osVersion,
      appVersion: metadata.appVersion,
      appBuild: metadata.appBuild,
      locale: metadata.locale,
      timezone: metadata.timezone,
      notificationPermission: permission,
    );

    if (kDebugMode) {
      debugPrint(
        '[Device] Registering '
        'platform=${request.platform} '
        'permission=${request.notificationPermission} '
        'hasToken=${request.pushToken != null}',
      );
    }

    await _deviceRemote.registerDevice(request);
  }

  /// Skip / local deny must report [denied] even if OS is still notDetermined.
  Future<String> _permissionForRegistration() async {
    final asked = await _permissionService.hasAsked();
    final allowed = await _permissionService.isNotificationAllowed();
    if (asked && !allowed) {
      return NotificationPermissionValues.denied;
    }
    return _permissionService.currentPermissionStatus();
  }

  @override
  Future<void> applyAllowChoice() async {
    final status = await _permissionService.requestOsPermission();
    final allowed = status == NotificationPermissionValues.granted;
    await _permissionService.markAsked(allowed: allowed);
    registerDeviceInBackground();
  }

  @override
  Future<void> applySkipChoice() async {
    await _permissionService.markAsked(allowed: false);
    registerDeviceInBackground();
  }

  @override
  void dispose() {
    unawaited(_tokenRefreshSubscription?.cancel());
    _tokenRefreshSubscription = null;
    _initialized = false;
  }
}

/// No-op implementation for widget tests (avoids Firebase).
class NoOpDeviceRegistrationService implements DeviceRegistrationService {
  @override
  Future<void> initialize() async {}

  @override
  void registerDeviceInBackground() {}

  @override
  Future<void> registerDevice() async {}

  @override
  Future<bool> shouldPromptForPermission() async => false;

  @override
  Future<void> applyAllowChoice() async {}

  @override
  Future<void> applySkipChoice() async {}

  @override
  void dispose() {}
}
