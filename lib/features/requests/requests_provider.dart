

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/requests_model.dart';
import 'package:frontend/features/requests/requests_data_source.dart';

final requestsProvider = AsyncNotifierProvider<RequestsProvider, List<RequestsModel>?>(RequestsProvider.new);

class RequestsProvider extends AsyncNotifier<List<RequestsModel>?> {
  @override
  Future<List<RequestsModel>?> build() async {

    getRequests();

    // return null;
  }


  Future<void> createQuickHelp() async {
    final requestsProvider = ref.read(requestsSourceProvider);

    state = AsyncValue.loading();

    state = await AsyncValue.guard(() async {

      await requestsProvider.createQuickHelp();

      }
    );
  }

  Future<void> getRequests({int limit = 50}) async {
    final requestsProvider = ref.read(requestsSourceProvider);

    state = AsyncValue.loading();

    state = await AsyncValue.guard(() async {

      final response = await requestsProvider.getRequests(limit);

      final requestsRes = response.map((e) => RequestsModel.fromJson(e as Map<String, dynamic>)).toList();

      return requestsRes;
    }
    );
  }
}