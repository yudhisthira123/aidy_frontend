import 'package:aidy_mobile/application/auth/authentication_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_lokale_api.dart';

void main() {
  test('login saves the token and returns the user', () async {
    final api = FakeLokaleApi()
      ..response = {
        'token': 'jwt-token',
        'user': {'id': 'user-1', 'name': 'Amith'},
      };
    final service = AuthenticationService(api);

    final user = await service.authenticate(
      registration: false,
      email: '  user@example.com ',
      password: 'secret',
    );

    expect(api.method, 'POST');
    expect(api.path, '/api/auth/login');
    expect(api.body, {'email': 'user@example.com', 'password': 'secret'});
    expect(api.token, 'jwt-token');
    expect(user.name, 'Amith');
  });

  test('registration normalizes account fields', () async {
    final api = FakeLokaleApi()
      ..response = {
        'token': 'registered-token',
        'user': {'id': 'user-2'},
      };
    final service = AuthenticationService(api);

    await service.authenticate(
      registration: true,
      name: '  New User ',
      email: ' new@example.com ',
      password: 'password',
    );

    expect(api.path, '/api/auth/register');
    expect(api.body, {
      'email': 'new@example.com',
      'password': 'password',
      'name': 'New User',
    });
  });

  test('restore returns null without a persisted token', () async {
    final api = FakeLokaleApi();
    final service = AuthenticationService(api);

    expect(await service.restore(), isNull);
    expect(api.restored, isTrue);
    expect(api.path, isNull);
  });

  test('restore loads the current user for an existing token', () async {
    final api = FakeLokaleApi()
      ..token = 'existing-token'
      ..response = {
        'user': {'id': 'user-3'},
      };
    final service = AuthenticationService(api);

    expect((await service.restore())?.id, 'user-3');
    expect(api.path, '/api/auth/me');
  });

  test('sign out clears local credentials even when the API fails', () async {
    final api = FakeLokaleApi()
      ..token = 'existing-token'
      ..error = StateError('offline');
    final service = AuthenticationService(api);

    await expectLater(service.signOut(), throwsStateError);
    expect(api.cleared, isTrue);
    expect(api.token, isNull);
  });
}
