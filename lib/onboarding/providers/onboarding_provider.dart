import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/dio_client.dart';
import 'package:frontend/onboarding/models/user_model.dart';
import 'package:frontend/onboarding/repositories/onboarding_data_source.dart';

final onBoardingProvider = AsyncNotifierProvider<OnBoardingNotifier, Result<UserModel, Exception>>(OnBoardingNotifier.new);



class OnBoardingNotifier extends AsyncNotifier<Result<UserModel, Exception>> {

  late OnBoardingDataSource onBoardingDataSource;

  OnBoardingNotifier() {
    onBoardingDataSource = OnBoardingDataSource(dio: DioClient().provideDio());
  }

  @override
  FutureOr<Result<UserModel, Exception>> build() {
    // TODO: implement build
    throw UnimplementedError();
  }

  Future<Result<UserModel, Exception>> register() async{
    final onBoardingProvider = ref.read(onBoardingDataSourceProvider);

    return await onBoardingProvider.registerUser("fullName", "email", "password");
  }

  Future<void> login() async {
    final onBoardingProvider = ref.read(onBoardingDataSourceProvider);
  }

  Future<void> logout() async {
    final onBoardingProvider = ref.read(onBoardingDataSourceProvider);
  }

}