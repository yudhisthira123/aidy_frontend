import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/user_model.dart';
import 'package:frontend/data/categories_provider.dart';
import 'package:frontend/data/secure_storage.dart';
import 'package:frontend/features/user_profile/registration_data_source.dart';

final registrationProvider = AsyncNotifierProvider<RegistrationProviderNotifier, AuthResponse?>(RegistrationProviderNotifier.new);

class RegistrationProviderNotifier extends AsyncNotifier<AuthResponse?> {

  @override
  Future<AuthResponse?> build() {

    return SecureStorage().getAuthResponse();
  }

  Future<void> register(String name, String email, String password) async{
    final regDataSourceProvider = ref.read(registrationDataSourceProvider);

    state = AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final response = await regDataSourceProvider.registerUser(name, email, password);

      final authResponse = AuthResponse.fromJson(response);

      ref.read(categoriesProvider.notifier).loadCategories();

      await SecureStorage().setAuthResponse(authResponse);

      return authResponse;
    });
  }

  Future<void> login(String email, String password) async {

    final regDataSourceProvider = ref.read(registrationDataSourceProvider);

    state = AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final response = await regDataSourceProvider.login(email, password);

      final authResponse = AuthResponse.fromJson(response);
      await SecureStorage().setAuthResponse(authResponse);

      return authResponse;
    });

  }

  Future<void> logout() async {
    final regDataSourceProvider = ref.read(registrationDataSourceProvider);
  }

}