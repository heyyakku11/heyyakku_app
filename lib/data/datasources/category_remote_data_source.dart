import 'package:yakku/data/models/category/category_response.dart';

abstract interface class CategoryRemoteDataSource {
  Future<List<CategoryResponse>> getCategories();
}
