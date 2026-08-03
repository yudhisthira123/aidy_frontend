import 'package:dio/dio.dart';

class DioClient {

  final _baseUrl = "https://pro5.promena.in/";

  final _receiverTimeout = const Duration(seconds: 60);
  final _connectTimeout = const Duration(seconds: 60);
  final _sendTimeout = const Duration(seconds: 60);

  late Dio _dio;

  DioClient._internal();
  static final DioClient _apiService = DioClient._internal();

  factory DioClient() => _apiService;

  void provideDio() {

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        receiveTimeout: _receiverTimeout,
        connectTimeout: _connectTimeout,
        sendTimeout: _sendTimeout,
        contentType: "application/json"
      )
    );

  }

}