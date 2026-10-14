import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/datasources/auth_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/auth/logout_request.dart';
import 'package:yakku/data/models/auth/refresh_token_request.dart';
import 'package:yakku/data/models/auth/send_otp_data.dart';
import 'package:yakku/data/models/auth/send_otp_request_model.dart';
import 'package:yakku/data/models/auth/token_response.dart';
import 'package:yakku/data/models/auth/verify_otp_data.dart';
import 'package:yakku/data/models/auth/verify_otp_request_model.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<SendOtpData> sendOtp(SendOtpRequestModel request) async {
    final payload = request.toJson();
    final url = '${dio.options.baseUrl}${ApiRoutes.sendOtp}';
    if (kDebugMode) {
      debugPrint('[AUTH] sendOtp REQUEST url=$url body=$payload');
    }

    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiRoutes.sendOtp,
        data: payload,
      );

      final body = response.data;
      if (kDebugMode) {
        debugPrint(
          '[AUTH] sendOtp RESPONSE status=${response.statusCode} '
          'url=${response.requestOptions.uri} body=$body',
        );
      }

      if (body == null) {
        throw StateError('Empty send OTP response');
      }

      final apiResponse = ApiResponse<SendOtpData>.fromJson(
        body,
        (json) => SendOtpData.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw StateError(apiResponse.message ?? 'Send OTP failed');
      }

      return apiResponse.data!;
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[AUTH] sendOtp ERROR status=${error.response?.statusCode} '
          'url=${error.requestOptions.uri} body=${error.response?.data}',
        );
      }
      rethrow;
    }
  }

  @override
  Future<VerifyOtpData> verifyOtp(
    VerifyOtpRequestModel request, {
    String? guestToken,
  }) async {
    final headers = <String, dynamic>{};
    if (guestToken != null && guestToken.isNotEmpty) {
      headers['X-Guest-Token'] = guestToken;
    }

    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.verifyOtp,
      data: request.toJson(),
      options: Options(headers: headers.isEmpty ? null : headers),
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
      throw ApiException(
        kind: ApiErrorKind.badRequest,
        message: apiResponse.message ?? 'Verify OTP failed',
        code: DioErrorMapper.errorCodeFromBody(body),
      );
    }

    return apiResponse.data!;
  }

  @override
  Future<TokenResponse> refresh(RefreshTokenRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiRoutes.refresh,
      data: request.toJson(),
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Empty refresh token response');
    }

    final apiResponse = ApiResponse<TokenResponse>.fromJson(
      body,
      (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Refresh token failed');
    }

    return apiResponse.data!;
  }

  @override
  Future<void> logout(LogoutRequestModel request, {String? accessToken}) async {
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
