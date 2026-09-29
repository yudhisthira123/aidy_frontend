import 'package:aidy_mobile/application/catalog/catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_lokale_api.dart';

void main() {
  test('loads categories with their subcategories', () async {
    final api = FakeLokaleApi()
      ..response = {
        'categories': [
          {
            'id': 'help',
            'subcategories': [
              {'id': 'medical'},
            ],
          },
        ],
      };

    final categories = await CatalogService(api).categories();

    expect(api.path, '/api/categories?include=subcategories');
    expect(categories.single['id'], 'help');
  });
}
