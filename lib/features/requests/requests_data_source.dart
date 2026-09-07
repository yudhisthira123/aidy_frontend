

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/constants.dart';
import 'package:frontend/common/quick_request.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/dio_client.dart';

final requestsSourceProvider = Provider<RequestsDataSource>((ref) {
  return RequestsDataSource(dio: DioClient().provideDio());
});

class RequestsDataSource {
  final Dio dio;

  RequestsDataSource({required this.dio});

  Future<Result<QuickReqResponse, Exception>> createQuickHelp() async {

    try {

      final response = await dio.post(
          apiRequests,
        options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
      );

      return Success(QuickReqResponse());
    } on DioException catch(error) {
      return Failure(error);
    }

  }

  Future<List<dynamic>> getRequests(int limit) async {
    try {

      final response = await dio.get(
        apiRequests,
        options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
      );

      return response.data as List<dynamic>;
    } on DioException catch(error) {
      throw _handleDioError(error);
    }
  }

  String _handleDioError(DioException error) {
    if (error.response != null && error.response?.data != null) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'].toString();
      }
      return 'Server error: ${error.response?.statusCode}';
    }
    return 'Connection network failure. Please try again.';
  }


}