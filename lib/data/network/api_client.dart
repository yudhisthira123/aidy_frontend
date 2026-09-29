import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/aidy_request.dart';
import '../../domain/gateways/lokale_api.dart';

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, this.status);
  @override
  String toString() => message;
}

class ApiClient implements LokaleApi {
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://lokale.onrender.com',
  );
  @override
  String get baseUrl => defaultBaseUrl;
  final FlutterSecureStorage _storage;
  final http.Client _http;
  @override
  String? token;
  @override
  String language = 'en';
  @override
  void Function()? onUnauthorized;

  ApiClient({http.Client? httpClient, FlutterSecureStorage? storage})
    : _http = httpClient ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> restore() async => token = await _storage.read(key: 'aidy_jwt');
  @override
  Future<void> saveToken(String value) async {
    token = value;
    await _storage.write(key: 'aidy_jwt', value: value);
  }

  @override
  Future<void> clearToken() async {
    token = null;
    await _storage.delete(key: 'aidy_jwt');
  }

  @override
  Future<String?> readLocal(String key) => _storage.read(key: key);
  @override
  Future<void> writeLocal(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<List<AidyRequestModel>> getRequests({
    int limit = 50,
    String? cursor,
  }) async {
    final query = Uri(
      queryParameters: {
        'limit': limit.clamp(1, 100).toString(),
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    ).query;
    final data = await request('GET', '/api/requests?$query');
    return AidyRequestModel.listFromJson(data);
  }

  @override
  Future<dynamic> request(String method, String path, {Object? body}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': language,
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    try {
      late Future<http.Response> call;
      switch (method) {
        case 'GET':
          call = _http.get(uri, headers: headers);
        case 'POST':
          call = _http.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'PATCH':
          call = _http.patch(uri, headers: headers, body: jsonEncode(body));
        case 'PUT':
          call = _http.put(uri, headers: headers, body: jsonEncode(body));
        case 'DELETE':
          call = _http.delete(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        default:
          throw ArgumentError('Unsupported method');
      }
      response = await call.timeout(const Duration(seconds: 25));
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        'Unable to reach Lokale. Check your connection and try again.',
        0,
      );
    }
    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      data = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        await clearToken();
        onUnauthorized?.call();
      }
      throw ApiException(
        data is Map
            ? (data['message']?.toString() ?? 'Request failed')
            : 'Request failed',
        response.statusCode,
      );
    }
    return data;
  }
}
