

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/constants.dart';
import 'package:frontend/common/quick_request.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/dio_client.dart';

final quickHelpDataSourceProvider = Provider<QuickHelpDataSource>((ref) {
  return QuickHelpDataSource(dio: DioClient().provideDio());
});

class QuickHelpDataSource {
  final Dio dio;

  QuickHelpDataSource({required this.dio});

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

}