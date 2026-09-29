import '../../domain/gateways/lokale_api.dart';

final class CatalogService {
  CatalogService(this._api);

  final LokaleApi _api;

  Future<List<Map<String, dynamic>>> categories() async {
    final response = await _api.request(
      'GET',
      '/api/categories?include=subcategories',
    );
    return (response['categories'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }
}
