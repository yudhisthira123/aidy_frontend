import 'package:aidy_mobile/application/requests/request_service.dart';
import 'package:aidy_mobile/domain/entities/aidy_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_lokale_api.dart';

void main() {
  group('RequestService', () {
    test(
      'loads owned requests, taxonomy, and saved location together',
      () async {
        final api = FakeLokaleApi()
          ..requestModels = [AidyRequestModel.fromJson(_requestJson('mine-1'))]
          ..handler = (method, path, body) async => switch (path) {
            '/api/categories?include=subcategories' => {
              'categories': [
                {'id': 'medical'},
              ],
            },
            '/api/users/me/location' => {
              'location': {'latitude': 12.9, 'longitude': 77.6},
            },
            _ => throw StateError('Unexpected request: $method $path'),
          };

        final overview = await RequestService(api).overview();

        expect(overview.mine.single.id, 'mine-1');
        expect(overview.categories.single['id'], 'medical');
        expect(overview.savedLocation?['longitude'], 77.6);
      },
    );

    test('encodes discovery filters and pagination', () async {
      final api = FakeLokaleApi()
        ..response = {
          'requests': [
            {'_id': 'nearby-1'},
          ],
          'pagination': {'hasMore': true, 'nextCursor': 'cursor-2'},
        };

      final page = await RequestService(api)
          .discover({'category': 'local support', 'limit': '20'});

      expect(api.method, 'GET');
      expect(
        api.path,
        '/api/requests/discover?category=local+support&limit=20',
      );
      expect(page.requests.single['_id'], 'nearby-1');
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'cursor-2');
    });

    test(
      'updates coordinates and includes accuracy only when available',
      () async {
        final api = FakeLokaleApi()..response = const {};
        final service = RequestService(api);

        await service.updateLocation(
          latitude: 49.38,
          longitude: 8.57,
          accuracyMeters: 6.5,
          source: 'gps',
        );

        expect(api.method, 'PUT');
        expect(api.path, '/api/users/me/location');
        expect(api.body, {
          'latitude': 49.38,
          'longitude': 8.57,
          'source': 'gps',
          'accuracyMeters': 6.5,
        });
      },
    );

    test('refreshes helper matches before loading the inbox', () async {
      final api = FakeLokaleApi()
        ..handler = (method, path, body) async => path.endsWith('/inbox')
            ? {
                'requests': [
                  {'_id': 'help-1'},
                ],
              }
            : const {};

      final inbox = await RequestService(api).helperInbox();

      expect(api.requests.map((request) => request.path), [
        '/api/requests/helper/refresh',
        '/api/requests/helper/inbox',
      ]);
      expect(inbox.single['_id'], 'help-1');
    });

    test('creates the correct helper accept and reject payloads', () async {
      final api = FakeLokaleApi()..response = const {};
      final service = RequestService(api);

      await service.respond(
        requestId: 'request-1',
        decision: 'accept',
        etaMinutes: 15,
      );
      expect(api.body, {
        'decision': 'accept',
        'etaMinutes': 15,
        'additionalHelpers': 0,
        'equipment': const <String>[],
        'competencies': const <String>[],
      });

      await service.respond(requestId: 'request-1', decision: 'reject');
      expect(api.body, {
        'decision': 'reject',
        'additionalHelpers': 0,
        'equipment': const <String>[],
        'competencies': const <String>[],
        'reason': 'Unavailable',
      });
    });

    test('finds owned and helper requests by stable id', () async {
      final api = FakeLokaleApi()
        ..requestModels = [AidyRequestModel.fromJson(_requestJson('owned'))]
        ..response = {
          'requests': [
            {'_id': 'helper'},
          ],
        };
      final service = RequestService(api);

      expect(
        (await service.findCurrent('owned', owned: true))?['_id'],
        'owned',
      );
      expect(
        (await service.findCurrent('helper', owned: false))?['_id'],
        'helper',
      );
      expect(await service.findCurrent('missing', owned: true), isNull);
    });
  });
}

Map<String, dynamic> _requestJson(String id) => {
  '_id': id,
  'createdBy': 'user-1',
  'kind': 'help',
  'mainCategory': 'quick_help',
  'subcategory': 'medical',
  'location': {
    'label': 'Current location',
    'coordinates': [8.57, 49.38],
  },
  'status': 'created',
  'equipmentRequired': const [],
  'images': const [],
  'matchedHelpers': const [],
  'helpers': const [],
  'messages': const [],
  'createdAt': '2026-09-29T00:00:00.000Z',
  'updatedAt': '2026-09-29T00:00:00.000Z',
};
