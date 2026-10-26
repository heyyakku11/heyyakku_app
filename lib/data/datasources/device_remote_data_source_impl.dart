import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/device_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/device/device_response.dart';
import 'package:yakku/data/models/device/update_device_request.dart';

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  DeviceRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<DeviceResponse> getCurrentDevice(String installationId) async {
    final response = await dio.get<Map<String, dynamic>>(
      ApiRoutes.currentDevice,
      options: Options(headers: {'X-Installation-Id': installationId}),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty device response');
    }

    final apiResponse = ApiResponse<DeviceResponse>.fromJson(
      body,
      (json) => DeviceResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to load device');
    }

    return apiResponse.data!;
  }

  @override
  Future<DeviceResponse> updateCurrentDevice(
    String installationId,
    UpdateDeviceRequest request,
  ) async {
    final response = await dio.patch<Map<String, dynamic>>(
      ApiRoutes.currentDevice,
      data: request.toJson(),
      options: Options(headers: {'X-Installation-Id': installationId}),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty device update response');
    }

    final apiResponse = ApiResponse<DeviceResponse>.fromJson(
      body,
      (json) => DeviceResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Device update failed');
    }

    return apiResponse.data!;
  }
}
