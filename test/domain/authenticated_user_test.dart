import 'package:aidy_mobile/domain/entities/authenticated_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes identity, role, and onboarding state', () {
    final user = AuthenticatedUser.fromJson({
      '_id': 'user-1',
      'name': 'Amith',
      'email': 'amith@example.com',
      'role': 'admin',
      'onboarding': {'status': 'complete'},
    });

    expect(user.id, 'user-1');
    expect(user.name, 'Amith');
    expect(user.email, 'amith@example.com');
    expect(user.isAdmin, isTrue);
    expect(user.onboardingStatus, 'complete');
  });

  test('rejects user payloads without an identifier', () {
    expect(
      () => AuthenticatedUser.fromJson({'name': 'Missing id'}),
      throwsFormatException,
    );
  });

  test('returns a defensive JSON copy', () {
    final user = AuthenticatedUser.fromJson({'id': 'user-2'});
    final json = user.toJson()..['name'] = 'Changed';

    expect(json['name'], 'Changed');
    expect(user.name, isEmpty);
  });
}
