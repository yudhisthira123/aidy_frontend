
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/models/category.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/data/categories_data_source.dart';

final categoriesProvider = AsyncNotifierProvider<CategoriesProviderNotifier, CategoriesResponse?>(CategoriesProviderNotifier.new);

class CategoriesProviderNotifier extends AsyncNotifier<CategoriesResponse?> {

  @override
  FutureOr<CategoriesResponse?> build() {
    return null;
  }

  Future<void> loadCategories() async {

    final categoriesDataProvider = ref.read(categoriesDataSourceProvider);

    state = AsyncValue.loading();

    state = await AsyncValue.guard(() async {

      final result = await categoriesDataProvider.loadCategories();

      final categories = CategoriesResponse.fromJson(result);

      return categories;

    });
  }


}