import 'package:yakku/data/models/device/device_response.dart';
import 'package:yakku/data/models/device/update_device_request.dart';

abstract interface class DeviceRemoteDataSource {
  /// `PATCH /api/v1/devices/me`: updates the device the signed-in session was
  /// bound to at verify-OTP (permission, push token, metadata).
  Future<DeviceResponse> updateCurrentDevice(
    String installationId,
    UpdateDeviceRequest request,
  );
}
