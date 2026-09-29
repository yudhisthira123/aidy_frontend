import 'package:aidy_mobile/domain/entities/aidy_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lostRequest = <String, dynamic>{
    '_id': '6a8f0e45cddecd9fcc31f6ec',
    'createdBy': '6a8b111639d2b7dd227b570c',
    'requesterName': 'Yudhisthira Attry',
    'kind': 'lost',
    'mainCategory': 'lost_found',
    'subcategory': 'lost_item',
    'location': {
      'label': 'Current location',
      'coordinates': [8.576669, 49.3815364],
    },
    'urgency': null,
    'period': null,
    'equipmentRequired': <String>[],
    'description': 'cycle lost',
    'images': <String>[],
    'contactPreference': 'In-app chat',
    'status': 'created',
    'matchedHelpers': <String>[],
    'helpers': <Object>[],
    'messages': <Object>[],
    'autoCloseAt': null,
    'createdAt': '2026-08-26T16:03:17.214Z',
    'updatedAt': '2026-08-26T16:03:17.214Z',
    '__v': 0,
  };

  test('parses the documented lost request and preserves GeoJSON order', () {
    final request = AidyRequestModel.fromJson(lostRequest);

    expect(request.kind, AidyRequestKind.lost);
    expect(request.location.longitude, 8.576669);
    expect(request.location.latitude, 49.3815364);
    expect(request.contactPreference, 'In-app chat');
    expect(request.urgency, isNull);
    expect(request.toJson(), lostRequest);
  });

  test('uses the same base model for help and found request variants', () {
    final help = AidyRequestModel.fromJson({
      ...lostRequest,
      '_id': '6a8f0e45cddecd9fcc31f6ed',
      'kind': 'help',
      'mainCategory': 'quick_help',
      'subcategory': 'medical',
      'urgency': 'immediately',
      'period': 'Now',
      'status': 'searching',
    });
    final found = AidyRequestModel.fromJson({
      ...lostRequest,
      '_id': '6a8f0e45cddecd9fcc31f6ee',
      'kind': 'found',
      'subcategory': 'found_item',
      'description': 'Found a bicycle',
    });

    expect(help.kind, AidyRequestKind.help);
    expect(help.urgency, 'immediately');
    expect(found.kind, AidyRequestKind.found);
    expect(found.contactPreference, 'In-app chat');
    expect(help.toJson().keys.toSet(), found.toJson().keys.toSet());
    expect(help.toJson().keys.toSet(), lostRequest.keys.toSet());
  });

  test('parses privacy-filtered request records with a null creator', () {
    final request = AidyRequestModel.fromJson({
      ...lostRequest,
      'createdBy': null,
    });

    expect(request.createdBy, isNull);
    expect(request.toJson()['createdBy'], isNull);
  });

  test('rejects a malformed coordinate payload with a controlled error', () {
    expect(
      () => AidyRequestModel.fromJson({
        ...lostRequest,
        'location': {
          'label': 'Missing latitude',
          'coordinates': [8.5],
        },
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
