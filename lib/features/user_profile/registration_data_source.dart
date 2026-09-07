
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/base_data_source.dart';
import 'package:frontend/common/constants.dart';
import 'package:frontend/dio_client.dart';

final registrationDataSourceProvider = Provider<RegistrationDataSource>((ref) {
  return RegistrationDataSource(dio: DioClient().provideDio());
});


class RegistrationDataSource extends BaseDataSource{
  final Dio dio;

  RegistrationDataSource({required this.dio});

  Future<Map<String, dynamic>> registerUser(String fullName, String email, String password) async {

    try {
      final response = await dio.post(
          apiRegister,
          options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
          data: _getRegistrationData(fullName, email, password)
      );

      return response.data as Map<String, dynamic>;

    } on DioException catch(error) {
      throw handleDioError(error);
    }
  }

  Map<String, dynamic> _getRegistrationData(String fullName, String email, String password) {
    Map<String, dynamic> data = {};

    data['name'] = fullName;
    data['email'] = email;
    data['password'] = password;

    return data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async{
    try {

      final response = await dio.post(
          apiLogin,
          options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
          data: _getLoginData(email, password)
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch(error) {
      throw handleDioError(error);
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