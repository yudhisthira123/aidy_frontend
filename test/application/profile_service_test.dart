import 'package:aidy_mobile/application/profile/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_lokale_api.dart';

void main() {
  group('ProfileService', () {
    test('updates a user and returns the normalized envelope value', () async {
      final api = FakeLokaleApi()
        ..response = {
          'user': {'id': 'user-1', 'name': 'Updated'},
        };

      final user = await ProfileService(api)
          .updateUser('user-1', {'name': 'Updated'});

      expect(api.path, '/api/users/user-1');
      expect(api.body, {'name': 'Updated'});
      expect(user['name'], 'Updated');
    });

    test(
      'hard deletion clears local credentials after server success',
      () async {
        final api = FakeLokaleApi()
          ..token = 'token'
          ..response = const {};

        await ProfileService(api).deleteAccount('password');

        expect(api.path, '/api/users/me');
        expect(api.body, {'password': 'password', 'confirmation': 'DELETE'});
        expect(api.cleared, isTrue);
      },
    );

    test('maps test-notification delivery diagnostics', () async {
      final api = FakeLokaleApi()
        ..response = {
          'sent': 1,
          'devicesFound': 2,
          'errorCodes': ['invalid-token'],
        };

      final result = await ProfileService(api).testNotification();

      expect(result.sent, 1);
      expect(result.devicesFound, 2);
      expect(result.errorCodes, ['invalid-token']);
    });

    test('loads and saves notification preferences with taxonomy', () async {
      final api = FakeLokaleApi()
        ..handler = (method, path, body) async {
          if (method == 'PUT') {
            return {'notificationPreferences': body};
          }
          if (path.startsWith('/api/categories')) {
            return {
              'categories': [
                {'id': 'medical'},
              ],
            };
          }
          return {
            'notificationPreferences': {'enabled': true},
          };
        };
      final service = ProfileService(api);

      final data = await service.notificationPreferences();
      expect(data.preferences['enabled'], isTrue);
      expect(data.categories.single['id'], 'medical');

      final saved = await service.saveNotificationPreferences({
        'enabled': false,
      });
      expect(saved['enabled'], isFalse);
    });
  });
}
