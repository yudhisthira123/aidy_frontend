import 'package:aidy_mobile/application/auth/authentication_service.dart';
import 'package:aidy_mobile/domain/entities/aidy_request.dart';
import 'package:aidy_mobile/domain/gateways/lokale_api.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeLokaleApi implements LokaleApi {
  @override
  String get baseUrl => 'https://example.test';
  @override
  String? token;
  @override
  String language = 'en';
  @override
  void Function()? onUnauthorized;

  String? method;
  String? path;
  Object? body;
  dynamic response;
  Object? error;
  bool restored = false;
  bool cleared = false;

  @override
  Future<void> clearToken() async {
    token = null;
    cleared = true;
  }

  @override
  Future<List<AidyRequestModel>> getRequests({
    int limit = 50,
    String? cursor,
  }) async => [];

  @override
  Future<String?> readLocal(String key) async => null;

  @override
  Future<dynamic> request(String method, String path, {Object? body}) async {
    this.method = method;
    this.path = path;
    this.body = body;
    if (error case final failure?) throw failure;
    return response;
  }

  @override
  Future<void> restore() async => restored = true;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> writeLocal(String key, String value) async {}
}

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
    expect(user['name'], 'Amith');
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

    expect((await service.restore())?['id'], 'user-3');
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
