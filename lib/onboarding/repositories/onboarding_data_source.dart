
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:frontend/common/constants.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/onboarding/models/user_model.dart';

abstract class OnBoardingBase {
  UserModel _getUserModel(Response response) {
    Map<String, dynamic> responseData = response.data;
    Map<String, dynamic> data = responseData['data'];
    Map<String, dynamic> userModel = data['userResponseModel'];

    return UserModel(
        fullName: userModel['name'],
        email: userModel['email'],
        id: userModel['id'],
        token: userModel['token'],
        tokenType: userModel['tokenType']
    );
  }
}

class UserRegistrationResponse extends OnBoardingBase{

  Result<UserModel, Exception> parseResponse(String fullName, String email, String password, Response response) {

    if(response.statusCode == 201) {
      if(response.data['data'] != null) {
        return Success(_getUserModel(response));
      }
      else {
        return Failure(Exception(response.data['message']));
      }
    }
    else{
      return Failure(Exception(response.statusMessage), statusCode: response.statusCode);
    }
  }
}

class UserLoginResponse extends OnBoardingBase {
  Result<UserModel, Exception> parseResponse(String email, Response response) {

    if(response.statusCode == 200) {
      if(response.data['data'] != null) {
        return Success(_getUserModel(response));
      }
      else {
        return Failure(Exception(response.data['message']));
      }
    }
    else {
     return Failure(Exception(response.statusMessage));
    }
  }
}

class OnBoardingDataSource {
  final Dio dio;

  OnBoardingDataSource({required this.dio});

  Future<Result<UserModel, Exception>> registerUser(String fullName, String email, String password) async {

    try {
      final response = await dio.post(
          apiRegister,
          options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
          data: _getRegistrationData(fullName, email, password)
      );

      final userRegistrationResponse = UserRegistrationResponse();
      final result = userRegistrationResponse.parseResponse(fullName, email, password, response);

      return result;

    } on DioException catch(error) {
      return Failure(error);
    }
  }

  Map<String, dynamic> _getRegistrationData(String fullName, String email, String password) {
    Map<String, dynamic> data = {};

    data['name'] = fullName;
    data['email'] = email;
    data['passPhrase'] = password;

    return data;
  }

  Future<Result<UserModel, Exception>> login(String email, String password) async{
    try {

      final response = await dio.post(
        apiLogin,
        options: Options(headers: {HttpHeaders.contentTypeHeader: "application/json"}),
        data: _getLoginData(email, password)
      );

      final userLoginResponse = UserLoginResponse();
      final result = userLoginResponse.parseResponse(email, response);

      return result;
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

  }

}