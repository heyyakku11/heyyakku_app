import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceMetadata {
  const DeviceMetadata({
    required this.platform,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
    this.appBuild,
    this.locale,
    this.timezone,
  });

  final String platform;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final String? appBuild;
  final String? locale;
  final String? timezone;
}

class DeviceMetadataProvider {
  DeviceMetadataProvider({DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  Future<DeviceMetadata> collect() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final locale = PlatformDispatcher.instance.locale.toLanguageTag();
    final timezone = DateTime.now().timeZoneName;

    if (kIsWeb) {
      return DeviceMetadata(
        platform: 'android',
        appVersion: packageInfo.version,
        appBuild: packageInfo.buildNumber,
        locale: locale,
        timezone: timezone,
      );
    }

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return DeviceMetadata(
        platform: 'android',
        deviceModel: info.model,
        osVersion: info.version.release,
        appVersion: packageInfo.version,
        appBuild: packageInfo.buildNumber,
        locale: locale,
        timezone: timezone,
      );
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return DeviceMetadata(
        platform: 'ios',
        deviceModel: info.utsname.machine,
        osVersion: info.systemVersion,
        appVersion: packageInfo.version,
        appBuild: packageInfo.buildNumber,
        locale: locale,
        timezone: timezone,
      );
    }

    return DeviceMetadata(
      platform: Platform.operatingSystem,
      appVersion: packageInfo.version,
      appBuild: packageInfo.buildNumber,
      locale: locale,
      timezone: timezone,
    );
  }
}
