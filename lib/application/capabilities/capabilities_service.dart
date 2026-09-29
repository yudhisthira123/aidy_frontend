import '../../domain/gateways/lokale_api.dart';

final class CapabilitiesService {
  CapabilitiesService(this._api);

  final LokaleApi _api;

  Future<void> saveProgress(Map<String, dynamic> body) async {
    await _api.request('PATCH', '/api/user-capabilities', body: body);
  }

  Future<Map<String, dynamic>> complete() => _finish('complete');

  Future<Map<String, dynamic>> skip() => _finish('skip');

  Future<Map<String, dynamic>> _finish(String action) async {
    final response = await _api.request(
      'POST',
      '/api/user-capabilities/$action',
    );
    return Map<String, dynamic>.from(response['user'] as Map);
  }
}
