import 'package:yakku/data/models/device/device_response.dart';
import 'package:yakku/data/models/device/register_device_request.dart';

abstract interface class DeviceRemoteDataSource {
  Future<DeviceResponse> registerDevice(RegisterDeviceRequest request);
}
