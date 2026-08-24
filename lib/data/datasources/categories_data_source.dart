

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/constants.dart';
import 'package:frontend/common/models/category.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/dio_client.dart';

final categoriesDataSourceProvider = Provider<CategoriesDataSource>((ref) {
  return CategoriesDataSource(dio: DioClient().provideDio());
});

class CategoriesDataSource {
  final Dio dio;

  CategoriesDataSource({required this.dio});

  Future<Result<CategoriesResponse, Exception>> loadCategories() async{

    try {

      final response = await dio.get(
        apiSubCategories,
      );

      if(response.statusCode == 200) {
        final catResponse = CategoriesResponse.fromJson(response.data as Map<String, dynamic>);

        return Success(catResponse);
      }
      else {
        return Failure(Exception('Filed to get categories'), statusCode: response.statusCode);
      }

    } on DioException catch(error) {
      return Failure(error);
    }

  }
}