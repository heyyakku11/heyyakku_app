import 'package:dio/dio.dart';
import 'package:yakku/core/constants/api_constants.dart';

abstract final class ApiClient {
  static Dio create() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: const {
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
