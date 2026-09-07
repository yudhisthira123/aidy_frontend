

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/base_data_source.dart';
import 'package:frontend/common/constants.dart';
import 'package:frontend/common/quick_request.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/dio_client.dart';

final requestsSourceProvider = Provider<RequestsDataSource>((ref) {
  return RequestsDataSource(dio: DioClient().provideDio());
});

class RequestsDataSource extends BaseDataSource {
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
      throw handleDioError(error);
    }
  }

}