

import 'package:dio/dio.dart';

class BaseDataSource {
  String handleDioError(DioException error) {
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