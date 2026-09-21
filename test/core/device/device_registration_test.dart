import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakku/core/device/installation_id_store.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';
import 'package:yakku/core/storage/storage_keys.dart';
import 'package:yakku/data/models/device/register_device_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InstallationIdStore', () {
    test('creates and persists a stable installation id', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = InstallationIdStore(
        storage: PreferenceStorageService(prefs: prefs),
      );

      final first = await store.getOrCreate();
      final second = await store.getOrCreate();

      expect(first, isNotEmpty);
      expect(second, first);
      expect(prefs.getString(StorageKeys.installationId), first);
    });
  });

  group('RegisterDeviceRequest', () {
    test('toJson omits null optional fields and includes required ones', () {
      const request = RegisterDeviceRequest(
        installationId: 'install-1',
        platform: 'android',
        notificationPermission: 'denied',
      );

      expect(request.toJson(), {
        'installationId': 'install-1',
        'platform': 'android',
        'notificationPermission': 'denied',
      });
    });

    test('toJson includes pushToken when present', () {
      const request = RegisterDeviceRequest(
        installationId: 'install-1',
        platform: 'ios',
        pushToken: 'token-abc',
        deviceModel: 'iPhone',
        osVersion: '18',
        appVersion: '1.0.0',
        appBuild: '12',
        locale: 'en-IN',
        timezone: 'IST',
        notificationPermission: 'granted',
      );

      expect(request.toJson(), {
        'installationId': 'install-1',
        'pushToken': 'token-abc',
        'platform': 'ios',
        'deviceModel': 'iPhone',
        'osVersion': '18',
        'appVersion': '1.0.0',
        'appBuild': '12',
        'locale': 'en-IN',
        'timezone': 'IST',
        'notificationPermission': 'granted',
      });
    });
  });
}
