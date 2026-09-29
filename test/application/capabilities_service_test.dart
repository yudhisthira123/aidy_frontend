import 'package:aidy_mobile/application/capabilities/capabilities_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_lokale_api.dart';

void main() {
  test('saves, completes, and skips capability setup', () async {
    final api = FakeLokaleApi()
      ..handler = (method, path, body) async => path.endsWith('complete')
          ? {
              'user': {'id': 'completed-user'},
            }
          : path.endsWith('skip')
          ? {
              'user': {'id': 'skipped-user'},
            }
          : const {};
    final service = CapabilitiesService(api);

    await service.saveProgress({'step': 2});
    expect(api.path, '/api/user-capabilities');
    expect(api.body, {'step': 2});
    expect((await service.complete())['id'], 'completed-user');
    expect((await service.skip())['id'], 'skipped-user');
  });
}
