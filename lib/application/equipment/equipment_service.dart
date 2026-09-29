import '../../domain/gateways/lokale_api.dart';

final class EquipmentService {
  EquipmentService(this._api);

  final LokaleApi _api;

  Future<List<Map<String, dynamic>>> availableEquipment() async {
    final response = await _api.request('GET', '/api/equipment?available=true');
    return (response['equipment'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }
}
