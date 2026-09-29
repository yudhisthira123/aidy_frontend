import '../../domain/gateways/lokale_api.dart';

final class NotificationPreferencesData {
  const NotificationPreferencesData({
    required this.preferences,
    required this.categories,
  });

  final Map<String, dynamic> preferences;
  final List<Map<String, dynamic>> categories;
}

final class TestNotificationResult {
  const TestNotificationResult({
    required this.sent,
    required this.devicesFound,
    required this.errorCodes,
  });

  final int sent;
  final int devicesFound;
  final List<String> errorCodes;
}

final class ProfileService {
  ProfileService(this._api);

  final LokaleApi _api;

  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> body,
  ) async {
    final response = await _api.request(
      'PATCH',
      '/api/users/$userId',
      body: body,
    );
    return Map<String, dynamic>.from(response['user'] as Map);
  }

  Future<void> deleteAccount(String password) async {
    await _api.request(
      'DELETE',
      '/api/users/me',
      body: {'password': password, 'confirmation': 'DELETE'},
    );
    await _api.clearToken();
  }

  Future<TestNotificationResult> testNotification() async {
    final response = await _api.request(
      'POST',
      '/api/users/me/test-notification',
    );
    return TestNotificationResult(
      sent: (response['sent'] as num?)?.toInt() ?? 0,
      devicesFound: (response['devicesFound'] as num?)?.toInt() ?? 0,
      errorCodes: (response['errorCodes'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  Future<NotificationPreferencesData> notificationPreferences() async {
    final results = await Future.wait([
      _api.request('GET', '/api/users/me/notification-preferences'),
      _api.request('GET', '/api/categories?include=subcategories'),
    ]);
    return NotificationPreferencesData(
      preferences: Map<String, dynamic>.from(
        results[0]['notificationPreferences'] as Map? ?? const {},
      ),
      categories: (results[1]['categories'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> saveNotificationPreferences(
    Map<String, dynamic> body,
  ) async {
    final response = await _api.request(
      'PUT',
      '/api/users/me/notification-preferences',
      body: body,
    );
    return Map<String, dynamic>.from(
      response['notificationPreferences'] as Map,
    );
  }
}
