import 'package:yakku/data/models/device/register_device_request.dart';

abstract interface class DeviceRemoteDataSource {
  Future<void> registerDevice(RegisterDeviceRequest request);
}
