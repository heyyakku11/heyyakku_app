import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/core/device/device_metadata_provider.dart';
import 'package:yakku/core/device/installation_id_store.dart';
import 'package:yakku/core/device/notification_permission_service.dart';
import 'package:yakku/core/device/push_token_provider.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/datasources/device_remote_data_source.dart';
import 'package:yakku/data/models/device/device_response.dart';
import 'package:yakku/data/models/device/login_device_model.dart';
import 'package:yakku/data/models/device/update_device_request.dart';

/// Coordinates installation ID, notification permission, FCM token and the
/// backend device record.
///
/// The device is created by the server during verify-OTP (the installation id
/// and platform travel inside that request, see [loginDevice]). This service
/// only *updates* that record afterwards with `PATCH /devices/me`: the
/// notification permission, the FCM token and device metadata.
abstract class DeviceRegistrationService {
  Future<void> initialize();

  /// The installation id and platform to send with verify-OTP.
  Future<LoginDeviceModel> loginDevice();

  /// Fire-and-forget device update; safe to call from UI without awaiting.
  void syncDeviceInBackground();

  /// Sends the current permission, FCM token and metadata to the server.
  Future<void> syncDevice();

  /// The server's view of this installation: its notification permission and
  /// whether push is switched on. Both are per device.
  Future<DeviceResponse> loadCurrentDevice();

  /// Switches push on or off for this installation only (other devices of the
  /// account are unaffected). Turning it on asks for the OS permission first
  /// when it has not been granted. Returns the server state, whose
  /// `isPushAllowed` stays false if the user did not grant the permission.
  Future<DeviceResponse> setPushAllowed(bool allowed);

  Future<bool> shouldPromptForPermission();

  Future<bool> isNotificationAllowed();

  /// Requests OS permission, stores the result, and updates the device.
  /// Returns whether the OS granted notification permission.
  Future<bool> applyAllowChoice();

  Future<void> applySkipChoice();

  void dispose();
}

class DeviceRegistrationServiceImpl
    with WidgetsBindingObserver
    implements DeviceRegistrationService {
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
  bool _syncInFlight = false;
  bool _syncAgain = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    _tokenRefreshSubscription ??= _pushTokenProvider.onTokenRefresh.listen((
      newToken,
    ) {
      if (kDebugMode) {
        debugPrint('[FCM] Token refreshed (len=${newToken.length})');
      }
      syncDeviceInBackground();
    });
  }

  @override
  Future<LoginDeviceModel> loginDevice() async {
    final installationId = await _installationIdStore.getOrCreate();
    final metadata = await _metadataProvider.collect();
    return LoginDeviceModel(
      installationId: installationId,
      platform: metadata.platform,
    );
  }

  @override
  void syncDeviceInBackground() {
    unawaited(syncDevice());
  }

  @override
  Future<bool> shouldPromptForPermission() async {
    if (!_authController.isLoggedIn) return false;
    return !(await _permissionService.hasAsked());
  }

  @override
  Future<bool> isNotificationAllowed() {
    return _permissionService.isNotificationAllowed();
  }

  @override
  Future<void> syncDevice() async {
    if (!_authController.isLoggedIn) return;
    if (_syncInFlight) {
      // A change arrived mid-request (for example the user just answered the
      // permission prompt); run once more so the latest state is what ends up
      // on the server.
      _syncAgain = true;
      return;
    }

    _syncInFlight = true;
    try {
      do {
        _syncAgain = false;
        try {
          await _syncOnce();
        } catch (error) {
          if (kDebugMode) {
            final mapped = DioErrorMapper.map(
              error,
              fallback: 'Device update failed',
            );
            debugPrint('[Device] Update failed: ${mapped.message}');
          }
        }
      } while (_syncAgain && _authController.isLoggedIn);
    } finally {
      _syncInFlight = false;
    }
  }

  Future<DeviceResponse> _syncOnce({bool? isPushAllowed}) async {
    final installationId = await _installationIdStore.getOrCreate();
    final metadata = await _metadataProvider.collect();
    final permission = await _permissionForSync();

    // A token is only worth sending once the user has allowed notifications;
    // the server ignores it for a denied permission anyway.
    final pushToken = permission == NotificationPermissionValues.granted
        ? await _pushTokenProvider.getToken()
        : null;

    final request = UpdateDeviceRequest(
      pushToken: pushToken,
      deviceModel: metadata.deviceModel,
      osVersion: metadata.osVersion,
      appVersion: metadata.appVersion,
      appBuild: metadata.appBuild,
      locale: metadata.locale,
      timezone: metadata.timezone,
      notificationPermission: permission,
      isPushAllowed: isPushAllowed,
    );

    if (kDebugMode) {
      debugPrint(
        '[Device] Updating '
        'permission=${request.notificationPermission} '
        'hasToken=${request.pushToken != null}',
      );
    }

    return _deviceRemote.updateCurrentDevice(installationId, request);
  }

  @override
  Future<DeviceResponse> loadCurrentDevice() async {
    final installationId = await _installationIdStore.getOrCreate();
    return _deviceRemote.getCurrentDevice(installationId);
  }

  @override
  Future<DeviceResponse> setPushAllowed(bool allowed) async {
    if (allowed) {
      final status = await _permissionService.currentPermissionStatus();
      if (status != NotificationPermissionValues.granted) {
        final result = await _permissionService.requestOsPermission();
        await _permissionService.markAsked(
          allowed: result == NotificationPermissionValues.granted,
        );
      }
    }
    return _syncOnce(isPushAllowed: allowed);
  }

  /// The permission to report. The OS is the source of truth whenever it has an
  /// answer, so enabling notifications in the system settings is picked up even
  /// after the user skipped the in-app prompt. Only while the OS has not been
  /// asked (notDetermined) does a skipped prompt count as [denied].
  Future<String> _permissionForSync() async {
    final os = await _permissionService.currentPermissionStatus();
    if (os != NotificationPermissionValues.unknown) {
      // Keep the local flags in step so they never contradict the OS.
      final granted = os == NotificationPermissionValues.granted;
      if (granted != await _permissionService.isNotificationAllowed()) {
        await _permissionService.markAsked(allowed: granted);
      }
      return os;
    }

    final asked = await _permissionService.hasAsked();
    final allowed = await _permissionService.isNotificationAllowed();
    return asked && !allowed
        ? NotificationPermissionValues.denied
        : NotificationPermissionValues.unknown;
  }

  @override
  Future<bool> applyAllowChoice() async {
    final status = await _permissionService.requestOsPermission();
    final allowed = status == NotificationPermissionValues.granted;
    await _permissionService.markAsked(allowed: allowed);
    syncDeviceInBackground();
    return allowed;
  }

  @override
  Future<void> applySkipChoice() async {
    await _permissionService.markAsked(allowed: false);
    syncDeviceInBackground();
  }

  /// The user may have changed the notification permission in the system settings
  /// while the app was in the background; report it as soon as the app is back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncDeviceInBackground();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
  Future<LoginDeviceModel> loginDevice() async => const LoginDeviceModel(
    installationId: 'test-installation',
    platform: 'android',
  );

  @override
  void syncDeviceInBackground() {}

  @override
  Future<void> syncDevice() async {}

  @override
  Future<DeviceResponse> loadCurrentDevice() async => const DeviceResponse(
    installationId: 'test-installation',
    platform: 'android',
    isActive: true,
  );

  @override
  Future<DeviceResponse> setPushAllowed(bool allowed) async => DeviceResponse(
    installationId: 'test-installation',
    platform: 'android',
    isActive: true,
    isPushAllowed: allowed,
  );

  @override
  Future<bool> shouldPromptForPermission() async => false;

  @override
  Future<bool> isNotificationAllowed() async => false;

  @override
  Future<bool> applyAllowChoice() async => false;

  @override
  Future<void> applySkipChoice() async {}

  @override
  void dispose() {}
}
