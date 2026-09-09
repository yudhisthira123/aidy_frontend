
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/constants.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/dio_client.dart';
import 'package:frontend/common/user_model.dart';

final userCapabilitiesDataSourceProvider = Provider<UserCapabilitiesDataSource>((ref) {
  return UserCapabilitiesDataSource(dio: DioClient().provideDio());
});

class UserCapabilitiesDataSource {
  final Dio dio;

  UserCapabilitiesDataSource({required this.dio});

  Future<Result<AuthResponse, Exception>> getUserCapabilities() async {

    try {
      final response = await dio.post(
          apiOnBoarding,
          options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
      );

      final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);

      return Success(authResponse);

    } on DioException catch(error) {
      return Failure(error);
    }
  }

  Future<Result<AuthResponse, Exception>> saveUserCapabilities(String jsonCapabilities) async{
    try {
      final response = await dio.patch(
        apiOnBoarding,
        options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
        data: jsonCapabilities
      );

      final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);

      return Success(authResponse);
    } on DioException catch(error) {
      return Failure(error);
    }
  }

  Future<Result<AuthResponse, Exception>> completeUserCapabilities(String jsonCapabilities) async {
    try {
      final response = await dio.post(
          apiOnBoarding,
          options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
          data: jsonCapabilities
      );

      final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);

      return Success(authResponse);
    } on DioException catch(error) {
      return Failure(error);
    }
  }

  Future<Result<AuthResponse, Exception>> skipUserCapabilities() async {
    try {
      final response = await dio.post(
          apiOnBoarding,
          options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
      );

      final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);

      return Success(authResponse);
    } on DioException catch(error) {
      return Failure(error);
    }
  }

}