import '../../domain/entities/authenticated_user.dart';
import '../../domain/gateways/lokale_api.dart';

/// Coordinates authentication and session persistence without depending on UI,
/// HTTP, secure-storage implementations, or platform plugins.
final class AuthenticationService {
  AuthenticationService(this._api);

  final LokaleApi _api;

  Future<AuthenticatedUser> authenticate({
    required bool registration,
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _api.request(
      'POST',
      registration ? '/api/auth/register' : '/api/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
        if (registration) 'name': name?.trim() ?? '',
      },
    );
    final result = Map<String, dynamic>.from(response as Map);
    final token = result['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const FormatException('Authentication response is incomplete.');
    }
    final user = AuthenticatedUser.fromJson(result['user']);
    await _api.saveToken(token);
    return user;
  }

  Future<AuthenticatedUser?> restore() async {
    await _api.restore();
    if (_api.token == null) return null;
    final response = await _api.request('GET', '/api/auth/me');
    return AuthenticatedUser.fromJson((response as Map)['user']);
  }

  Future<void> signOut() async {
    try {
      await _api.request('POST', '/api/auth/logout');
    } finally {
      await _api.clearToken();
    }
  }
}
