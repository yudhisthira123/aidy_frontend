import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/common/user_model.dart';
import 'package:frontend/features/user_capabilities/datasources/user_capabilities_data_source.dart';

final userCapabilitiesProvider = AsyncNotifierProvider<UserCapabilitiesNotifier, Result<UserModel, Exception>>(UserCapabilitiesNotifier.new);

class UserCapabilitiesNotifier extends AsyncNotifier<Result<UserModel, Exception>> {


  @override
  FutureOr<Result<UserModel, Exception>> build() {
    // TODO: implement build
    throw UnimplementedError();
  }

  Future<void> getOnBoardingState() async {
    final on = ref.read(userCapabilitiesDataSourceProvider);
  }

  Future<void> saveOnBoardingState() async {
    final on = ref.read(userCapabilitiesDataSourceProvider);
  }

  Future<void> completeOnBoardingState() async {
    final on = ref.read(userCapabilitiesDataSourceProvider);
  }

  Future<void> skipOnBoardingState() async {
    final on = ref.read(userCapabilitiesDataSourceProvider);
  }

}