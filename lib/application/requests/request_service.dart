import '../../domain/entities/aidy_request.dart';
import '../../domain/gateways/lokale_api.dart';

final class RequestOverview {
  const RequestOverview({
    required this.mine,
    required this.categories,
    this.savedLocation,
  });

  final List<AidyRequestModel> mine;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? savedLocation;
}

final class RequestDiscoveryPage {
  const RequestDiscoveryPage({
    required this.requests,
    required this.hasMore,
    this.nextCursor,
  });

  final List<Map<String, dynamic>> requests;
  final bool hasMore;
  final String? nextCursor;
}

/// Owns request endpoint orchestration so presentation code contains no URL or
/// response-envelope knowledge.
final class RequestService {
  RequestService(this._api);

  final LokaleApi _api;

  Future<RequestOverview> overview() async {
    final results = await Future.wait([
      _api.getRequests(),
      _api.request('GET', '/api/categories?include=subcategories'),
      _api.request('GET', '/api/users/me/location'),
    ]);
    final taxonomy = results[1] as Map? ?? const {};
    final locationEnvelope = results[2] as Map? ?? const {};
    return RequestOverview(
      mine: List<AidyRequestModel>.from(results[0] as List),
      categories: (taxonomy['categories'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false),
      savedLocation: switch (locationEnvelope['location']) {
        final Map location => Map<String, dynamic>.from(location),
        _ => null,
      },
    );
  }

  Future<RequestDiscoveryPage> discover(Map<String, String> parameters) async {
    final query = Uri(queryParameters: parameters).query;
    final response = await _api.request('GET', '/api/requests/discover?$query');
    final pagination = response['pagination'] as Map? ?? const {};
    return RequestDiscoveryPage(
      requests: (response['requests'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false),
      hasMore: pagination['hasMore'] == true,
      nextCursor: pagination['nextCursor']?.toString(),
    );
  }

  Future<dynamic> create(Map<String, dynamic> payload) =>
      _api.request('POST', '/api/requests', body: payload);

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    required String source,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'source': source,
    };
    if (accuracyMeters != null) {
      body['accuracyMeters'] = accuracyMeters;
    }
    await _api.request('PUT', '/api/users/me/location', body: body);
  }

  Future<List<Map<String, dynamic>>> helperInbox({bool refresh = true}) async {
    if (refresh) {
      try {
        await _api.request('POST', '/api/requests/helper/refresh');
      } catch (_) {}
    }
    final response = await _api.request('GET', '/api/requests/helper/inbox');
    return (response['requests'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<void> respond({
    required String requestId,
    required String decision,
    int etaMinutes = 10,
  }) => _api.request(
    'POST',
    '/api/requests/$requestId/responses',
    body: {
      'decision': decision,
      if (decision == 'accept') 'etaMinutes': etaMinutes,
      'additionalHelpers': 0,
      'equipment': const <String>[],
      'competencies': const <String>[],
      if (decision == 'reject') 'reason': 'Unavailable',
    },
  );

  Future<dynamic> sendMessage(String requestId, String body) => _api.request(
    'POST',
    '/api/requests/$requestId/messages',
    body: {'body': body},
  );

  Future<void> delete(String requestId) =>
      _api.request('DELETE', '/api/requests/$requestId');

  Future<dynamic> updateStatus(String requestId, String status) => _api.request(
    'PATCH',
    '/api/requests/$requestId/status',
    body: {'status': status},
  );

  Future<Map<String, dynamic>?> findCurrent(
    String requestId, {
    required bool owned,
  }) async {
    final response = owned
        ? await _api.getRequests()
        : await helperInbox(refresh: false);
    final records = response is List<AidyRequestModel>
        ? response.map((item) => item.toJson())
        : List<Map<String, dynamic>>.from(response as List);
    for (final item in records) {
      if (item['_id']?.toString() == requestId) return item;
    }
    return null;
  }
}
