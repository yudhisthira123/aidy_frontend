
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/common/models/category.dart';
import 'package:frontend/common/result.dart';
import 'package:frontend/data/datasources/categories_data_source.dart';

final categoriesProvider = AsyncNotifierProvider<CategoriesProviderNotifier, Result<CategoriesResponse, Exception>>(CategoriesProviderNotifier.new);

class CategoriesProviderNotifier extends AsyncNotifier<Result<CategoriesResponse, Exception>> {

  @override
  FutureOr<Result<CategoriesResponse, Exception>> build() {
    return Success(CategoriesResponse(categories: []));
  }

  Future<void> loadCategories() async {

    final categoriesDataProvider = ref.read(categoriesDataSourceProvider);

    await categoriesDataProvider.loadCategories();

  }


}