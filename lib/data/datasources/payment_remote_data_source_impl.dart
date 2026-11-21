import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/datasources/payment_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/payments/payment_models.dart';

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  PaymentRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<CreatePaymentOrderResponse> createOrder(
    CreatePaymentOrderRequest request,
  ) async {
    final response = await _post(
      ApiRoutes.paymentOrders,
      data: request.toJson(),
      fallback: 'Could not create payment order',
    );
    return _parse(
      response.data,
      CreatePaymentOrderResponse.fromJson,
      'Could not create payment order',
    );
  }

  @override
  Future<VerifyPaymentResponse> verify(VerifyPaymentRequest request) async {
    final response = await _post(
      ApiRoutes.paymentVerify,
      data: request.toJson(),
      fallback: 'Could not verify payment',
    );
    return _parse(
      response.data,
      VerifyPaymentResponse.fromJson,
      'Could not verify payment',
    );
  }

  @override
  Future<PaymentOrderStatus> getOrder(String orderId) async {
    final response = await _get(
      ApiRoutes.paymentOrder(orderId),
      fallback: 'Could not load payment status',
    );
    return _parse(
      response.data,
      PaymentOrderStatus.fromJson,
      'Could not load payment status',
    );
  }

  @override
  Future<PaymentHistoryPage> getHistory({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _get(
      ApiRoutes.paymentHistory,
      queryParameters: <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      },
      fallback: 'Could not load payment history',
    );
    final body = response.data;
    if (body == null) {
      throw StateError('Empty payment history response');
    }
    final api = ApiResponse<List<PaymentHistoryItem>>.fromJson(body, (json) {
      if (json is! List) return const <PaymentHistoryItem>[];
      return [
        for (final item in json)
          if (item is Map)
            PaymentHistoryItem.fromJson(Map<String, dynamic>.from(item)),
      ];
    });
    if (!api.success || api.data == null) {
      throw StateError(api.message ?? 'Could not load payment history');
    }
    return PaymentHistoryPage.fromApi(items: api.data!, meta: api.meta);
  }

  Future<Response<Map<String, dynamic>>> _post(
    String path, {
    required Object data,
    required String fallback,
  }) async {
    try {
      return await dio.post<Map<String, dynamic>>(path, data: data);
    } on DioException catch (error) {
      throw DioErrorMapper.map(error, fallback: fallback);
    }
  }

  Future<Response<Map<String, dynamic>>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
    required String fallback,
  }) async {
    try {
      return await dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      throw DioErrorMapper.map(error, fallback: fallback);
    }
  }

  T _parse<T>(
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>) parse,
    String failure,
  ) {
    if (body == null) throw StateError('Empty payment response');
    final api = ApiResponse<T>.fromJson(
      body,
      (json) => parse(Map<String, dynamic>.from(json as Map)),
    );
    if (!api.success || api.data == null) {
      throw StateError(api.message ?? failure);
    }
    return api.data as T;
  }
}
