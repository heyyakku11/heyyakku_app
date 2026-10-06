import 'package:dio/dio.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/datasources/category_remote_data_source.dart';
import 'package:yakku/data/models/auth/api_response.dart';
import 'package:yakku/data/models/category/category_response.dart';

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  CategoryRemoteDataSourceImpl(this.dio);

  final Dio dio;

  @override
  Future<List<CategoryResponse>> getCategories() async {
    final response = await dio.get<Map<String, dynamic>>(ApiRoutes.categories);

    final body = response.data;
    if (body == null) {
      throw StateError('Empty categories response');
    }

    final apiResponse = ApiResponse<List<CategoryResponse>>.fromJson(body, (
      json,
    ) {
      if (json is! List) return <CategoryResponse>[];
      return json
          .whereType<Map>()
          .map(
            (item) =>
                CategoryResponse.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    });

    if (!apiResponse.success || apiResponse.data == null) {
      throw StateError(apiResponse.message ?? 'Failed to load categories');
    }

    return apiResponse.data!;
  }
}
