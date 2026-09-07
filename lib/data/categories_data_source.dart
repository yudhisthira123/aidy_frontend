
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/base_data_source.dart';
import 'package:frontend/common/constants.dart';
import 'package:frontend/dio_client.dart';

final categoriesDataSourceProvider = Provider<CategoriesDataSource>((ref) {
  return CategoriesDataSource(dio: DioClient().provideDio());
});

class CategoriesDataSource extends BaseDataSource {
  final Dio dio;

  CategoriesDataSource({required this.dio});

  Future<Map<String, dynamic>> loadCategories() async{

    try {

      final response = await dio.get(
        apiSubCategories,
      );

      return response.data as Map<String, dynamic>;

    } on DioException catch(error) {
      throw handleDioError(error);
    }

  }
}