import '../../domain/gateways/lokale_api.dart';

/// Coordinates authentication and session persistence without depending on UI,
/// HTTP, secure-storage implementations, or platform plugins.
final class AuthenticationService {
  AuthenticationService(this._api);

  final LokaleApi _api;

  Future<Map<String, dynamic>> authenticate({
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
    final user = result['user'];
    if (token == null || token.isEmpty || user is! Map) {
      throw const FormatException('Authentication response is incomplete.');
    }
    await _api.saveToken(token);
    return Map<String, dynamic>.from(user);
  }

  Future<Map<String, dynamic>?> restore() async {
    await _api.restore();
    if (_api.token == null) return null;
    final response = await _api.request('GET', '/api/auth/me');
    final user = (response as Map)['user'];
    if (user is! Map) {
      throw const FormatException('Session response is incomplete.');
    }
    return Map<String, dynamic>.from(user);
  }

  Future<void> signOut() async {
    try {
      await _api.request('POST', '/api/auth/logout');
    } finally {
      await _api.clearToken();
    }
  }
}
