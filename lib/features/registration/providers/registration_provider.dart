import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/common//user_model.dart';
import 'package:frontend/features/registration/datasources/registration_data_source.dart';

final registrationProvider = AsyncNotifierProvider<RegistrationProviderNotifier, Result<AuthResponse, Exception>>(RegistrationProviderNotifier.new);

class RegistrationProviderNotifier extends AsyncNotifier<Result<AuthResponse, Exception>> {

  @override
  FutureOr<Result<AuthResponse, Exception>> build() {

    return Success(AuthResponse(user: null, token: '', tokenType: '', expiresIn: null));
  }

  Future<Result<UserModel, Exception>> register() async{
    final regDataSourceProvider = ref.read(registrationDataSourceProvider);

    final result = await regDataSourceProvider.registerUser("Attry", "attry@gmail.com", "password");

    return Success(UserModel(fullName: 'fullName', email: 'email'));
  }

  Future<Result<UserModel, Exception>> login() async {

    final regDataSourceProvider = ref.read(registrationDataSourceProvider);

    final result = await regDataSourceProvider.login("attry@gmail.com", "password");

    return Success(UserModel(fullName: 'fullName', email: 'email'));
  }

  Future<void> logout() async {
    final regDataSourceProvider = ref.read(registrationDataSourceProvider);
  }

}