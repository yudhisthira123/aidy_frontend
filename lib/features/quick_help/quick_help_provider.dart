

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/quick_help/quick_help_data_source.dart';

final quickHelpProvider = AsyncNotifierProvider<QuickHelpProvider, void>(QuickHelpProvider.new);

class QuickHelpProvider extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }


  Future<void> createQuickHelp() async {
    final quickDataSourceProvider = ref.read(quickHelpDataSourceProvider);

    state = AsyncValue.loading();

    state = await AsyncValue.guard(() async {

      await quickDataSourceProvider.createQuickHelp();

      }
    );
  }
}