
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/constants.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/dio_client.dart';
import 'package:frontend/common//user_model.dart';

final registrationDataSourceProvider = Provider<RegistrationDataSource>((ref) {
  return RegistrationDataSource(dio: DioClient().provideDio());
});


class RegistrationDataSource {
  final Dio dio;

  RegistrationDataSource({required this.dio});

  Future<Result<AuthResponse, Exception>> registerUser(String fullName, String email, String password) async {

    try {
      final response = await dio.post(
          apiRegister,
          options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
          data: _getRegistrationData(fullName, email, password)
      );

      if(response.statusCode == 201) {
        final authResponse =  AuthResponse.fromJson(response.data as Map<String, dynamic>);

        return Success(authResponse);
      }
      else {
        return Failure(Exception('Filed to register'), statusCode: response.statusCode);
      }

    } on DioException catch(error) {
      return Failure(error);
    }
  }

  Map<String, dynamic> _getRegistrationData(String fullName, String email, String password) {
    Map<String, dynamic> data = {};

    data['name'] = fullName;
    data['email'] = email;
    data['password'] = password;

    return data;
  }

  Future<Result<AuthResponse, Exception>> login(String email, String password) async{
    try {

      final response = await dio.post(
          apiLogin,
          options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
          data: _getLoginData(email, password)
      );

      if(response.statusCode == 200) {
        final authResponse =  AuthResponse.fromJson(response.data as Map<String, dynamic>);

        return Success(authResponse);
      }
      else {
        return Failure(Exception('Filed to login'), statusCode: response.statusCode);
      }
    } on DioException catch(error) {
      return Failure(error);
    }
  }

  Map<String, dynamic> _getLoginData(String email, String password) {
    Map<String, dynamic> data = {};

    data['email'] = email;
    data['password'] = password;

    return data;
  }

  Future<void> logout() async {

    try{
      final response = await dio.post(
        apiLogout
      );
    } on DioException catch(error) {
      // return Failure(error);
    }

  }

}