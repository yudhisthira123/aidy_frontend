import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient(this.dio);

  Future<Response> get(
      String path,
      Map<String, dynamic>? queryParams
      ) async {
    return await dio.get(
        path,
        queryParameters: queryParams
    );
  }

  Future<Response> post(
      String path,
      dynamic data
      ) async {
    return await dio.post(
        path,
        data: data
    );
  }

  Future<Response> put(
      String path,
      dynamic data
      ) async {

    return await dio.put(
      path,
      data: data
    );
  }
}