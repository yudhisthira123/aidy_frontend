import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/common/user_model.dart';
import 'package:frontend/data/secure_storage.dart';
import 'package:frontend/features/user_profile/registration_data_source.dart';

final registrationProvider = AsyncNotifierProvider<RegistrationProviderNotifier, AuthResponse?>(RegistrationProviderNotifier.new);

class RegistrationProviderNotifier extends AsyncNotifier<AuthResponse?> {

  @override
  Future<AuthResponse?> build() {

    return SecureStorage().getAuthResponse();
  }

  Future<void> register() async{
    final regDataSourceProvider = ref.read(registrationDataSourceProvider);

    state = AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final result = await regDataSourceProvider.registerUser("Attry", "attry@gmail.com", "password");
      return switch (result) {
        Success(value: final authResponse) => authResponse,
        Failure(exception: final error) => throw error,
      };
    });
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