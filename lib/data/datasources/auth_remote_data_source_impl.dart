import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/auth/logout_request.dart';
import 'package:yakku/data/models/auth/send_otp_data.dart';
import 'package:yakku/data/models/auth/send_otp_request_model.dart';
import 'package:yakku/data/models/auth/verify_otp_data.dart';
import 'package:yakku/data/models/auth/verify_otp_request_model.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<void> sendOtp(
    SendOtpRequestModel request,
  ) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.sendOtp,
      data: request.toJson(),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty send OTP response');
    }

    final apiResponse = ApiResponse<SendOtpData>.fromJson(
      body,
      (json) => SendOtpData.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success) {
      throw StateError(apiResponse.message ?? 'Send OTP failed');
    }
  }

  @override
  Future<VerifyOtpData> verifyOtp(
    VerifyOtpRequestModel request,
  ) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.verifyOtp,
      data: request.toJson(),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty verify OTP response');
    }

    final apiResponse = ApiResponse<VerifyOtpData>.fromJson(
      body,
      (json) => VerifyOtpData.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Verify OTP failed');
    }

    return apiResponse.data!;
  }

  @override
  Future<void> logout(
    LogoutRequestModel request, {
    String? accessToken,
  }) async {
    final headers = <String, dynamic>{};
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.logout,
      data: request.toJson(),
      options: Options(headers: headers.isEmpty ? null : headers),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty logout response');
    }

    final apiResponse = ApiResponse<void>.fromJson(body, null);

    if (!apiResponse.success) {
      throw StateError(apiResponse.message ?? 'Logout failed');
    }
  }
}
