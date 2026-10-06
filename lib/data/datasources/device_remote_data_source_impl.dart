import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/device_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/device/device_response.dart';
import 'package:yakku/data/models/device/register_device_request.dart';

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  DeviceRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<DeviceResponse> registerDevice(RegisterDeviceRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.registerDevice,
      data: request.toJson(),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty device registration response');
    }

    final apiResponse = ApiResponse<DeviceResponse>.fromJson(
      body,
      (json) => DeviceResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Device registration failed');
    }

    return apiResponse.data!;
  }
}
