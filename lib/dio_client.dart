import 'package:dio/dio.dart';
import 'package:frontend/common/user_model.dart';
import 'package:frontend/data/secure_storage.dart';

class DioClient {

  final _baseUrl = "https://lokale.onrender.com/";

  final _receiverTimeout = const Duration(seconds: 60);
  final _connectTimeout = const Duration(seconds: 60);
  final _sendTimeout = const Duration(seconds: 60);

  late Dio _dio;

  DioClient._internal();
  static final DioClient _apiService = DioClient._internal();

  factory DioClient() => _apiService;

  Dio provideDio() {

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        receiveTimeout: _receiverTimeout,
        connectTimeout: _connectTimeout,
        sendTimeout: _sendTimeout,
        contentType: "application/json"
      )
    );

    _dio.interceptors.add(TokenInterceptor(dio: _dio));

    return _dio;
  }
}

class TokenInterceptor extends Interceptor {
  final Dio dio;
  TokenInterceptor({required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {

    AuthResponse? authResponse = await SecureStorage().getAuthResponse();
    final token = authResponse?.token ?? '';

    if(token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    else {

    }

    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = '*/*';

    handler.next(options);
  }
}