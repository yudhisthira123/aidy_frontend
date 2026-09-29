import '../models/aidy_request.dart';

/// Application-facing contract for Lokale's remote and local session data.
///
/// Presentation code depends on this interface instead of a concrete HTTP
/// implementation. That keeps widgets testable and allows the transport or
/// persistence implementation to change without rewriting feature screens.
abstract interface class LokaleApi {
  String get baseUrl;
  String? get token;
  set token(String? value);
  String get language;
  set language(String value);
  void Function()? get onUnauthorized;
  set onUnauthorized(void Function()? callback);

  Future<void> restore();
  Future<void> saveToken(String value);
  Future<void> clearToken();
  Future<String?> readLocal(String key);
  Future<void> writeLocal(String key, String value);
  Future<List<AidyRequestModel>> getRequests({int limit, String? cursor});
  Future<dynamic> request(String method, String path, {Object? body});
}
