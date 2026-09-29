import 'package:aidy_mobile/application/admin/admin_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_lokale_api.dart';

void main() {
  group('AdminService', () {
    test('loads and maps the complete administration snapshot', () async {
      final api = FakeLokaleApi()
        ..handler = (method, path, body) async => switch (path) {
          '/api/admin/stats' => {
            'stats': {'totalUsers': 12},
          },
          '/api/admin/users' => {
            'users': [
              {'id': 'user-1'},
            ],
          },
          '/api/admin/requests' => {
            'requests': [
              {'_id': 'request-1'},
            ],
          },
          '/api/admin/equipment' => {
            'equipment': [
              {'_id': 'equipment-1'},
            ],
          },
          '/api/admin/categories' => {
            'categories': [
              {'_id': 'category-1'},
            ],
          },
          _ => throw StateError('Unexpected request: $path'),
        };

      final snapshot = await AdminService(api).load();

      expect(snapshot.stats['totalUsers'], 12);
      expect(snapshot.users.single['id'], 'user-1');
      expect(snapshot.requests.single['_id'], 'request-1');
      expect(snapshot.equipment.single['_id'], 'equipment-1');
      expect(snapshot.categories.single['_id'], 'category-1');
    });

    test(
      'selects create and update contracts from resource identity',
      () async {
        final api = FakeLokaleApi()..response = const {};
        final service = AdminService(api);

        await service.saveUser({'name': 'New user'});
        expect(api.method, 'POST');
        expect(api.path, '/api/admin/users');

        await service.saveEquipment({'name': 'Tool'}, id: 'equipment-1');
        expect(api.method, 'PUT');
        expect(api.path, '/api/admin/equipment/equipment-1');

        await service.saveCategory({'name': 'Medical'}, id: 'category-1');
        expect(api.path, '/api/admin/categories/category-1');
      },
    );

    test('encapsulates request state and destructive resource paths', () async {
      final api = FakeLokaleApi()..response = const {};
      final service = AdminService(api);

      await service.updateRequestStatus('request-1', 'completed');
      expect(api.body, {'status': 'completed'});

      await service.delete(AdminResource.requests, 'request-1');
      expect(api.path, '/api/admin/requests/request-1');

      await service.deleteSubcategory('category-1', 'subcategory-1');
      expect(
        api.path,
        '/api/admin/categories/category-1/subcategories/subcategory-1',
      );
    });
  });
}
