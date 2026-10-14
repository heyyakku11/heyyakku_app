import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/guest_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/guest/guest_response.dart';

class GuestRemoteDataSourceImpl implements GuestRemoteDataSource {
  GuestRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<GuestResponse> createGuest() async {
    final response = await dio.post<Map<String, dynamic>>(ApiRoutes.guests);

    final body = response.data;
    if (body == null) {
      throw StateError('Empty guest create response');
    }

    final apiResponse = ApiResponse<GuestResponse>.fromJson(
      body,
      (json) => GuestResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Create guest failed');
    }

    return apiResponse.data!;
  }
}
