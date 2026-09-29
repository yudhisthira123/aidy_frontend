import 'package:aidy_mobile/application/equipment/equipment_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_lokale_api.dart';

void main() {
  test('loads available equipment through the catalog contract', () async {
    final api = FakeLokaleApi()
      ..response = {
        'equipment': [
          {'_id': 'equipment-1', 'name': 'First aid kit'},
        ],
      };

    final equipment = await EquipmentService(api).availableEquipment();

    expect(api.path, '/api/equipment?available=true');
    expect(equipment.single['name'], 'First aid kit');
  });
}
