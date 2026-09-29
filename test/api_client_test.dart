import 'dart:convert';

import 'package:aidy_mobile/data/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('GET includes localization and bearer authentication headers', () async {
    late http.Request captured;
    final client =
        ApiClient(
            httpClient: MockClient((request) async {
              captured = request;
              return http.Response(jsonEncode({'ok': true}), 200);
            }),
          )
          ..token = 'jwt-token'
          ..language = 'de';

    expect(await client.request('GET', '/api/categories'), {'ok': true});
    expect(
      captured.url.toString(),
      '${ApiClient.defaultBaseUrl}/api/categories',
    );
    expect(captured.headers['Authorization'], 'Bearer jwt-token');
    expect(captured.headers['Accept-Language'], 'de');
    expect(captured.headers.containsKey('Content-Type'), isFalse);
  });

  test('POST serializes JSON and surfaces an API error message', () async {
    late http.Request captured;
    final client = ApiClient(
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'message': 'Invalid request'}), 422);
      }),
    );

    await expectLater(
      client.request('POST', '/api/requests', body: {'kind': 'help'}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.status, 'status', 422)
            .having((error) => error.message, 'message', 'Invalid request'),
      ),
    );
    expect(captured.headers['Content-Type'], 'application/json');
    expect(jsonDecode(captured.body), {'kind': 'help'});
  });

  test('returns null for an empty success response', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => http.Response('', 204)),
    );
    expect(await client.request('DELETE', '/api/push-token/device-1'), isNull);
  });

  test(
    'PATCH and PUT use the injected client and serialize their body',
    () async {
      final captured = <http.Request>[];
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured.add(request);
          return http.Response(jsonEncode({'method': request.method}), 200);
        }),
      );

      expect(
        await client.request(
          'PATCH',
          '/api/user-capabilities',
          body: {'step': 2},
        ),
        {'method': 'PATCH'},
      );
      expect(
        await client.request(
          'PUT',
          '/api/users/me/location',
          body: {'lat': 48.1},
        ),
        {'method': 'PUT'},
      );
      expect(captured.map((request) => request.method), ['PATCH', 'PUT']);
      expect(jsonDecode(captured[0].body), {'step': 2});
      expect(jsonDecode(captured[1].body), {'lat': 48.1});
    },
  );

  test('falls back to a generic error for malformed server JSON', () async {
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response('<html>failed</html>', 500),
      ),
    );
    await expectLater(
      client.request('GET', '/api/failure'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.status, 'status', 500)
            .having((error) => error.toString(), 'message', 'Request failed'),
      ),
    );
  });

  test('rejects unsupported methods before making a request', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );
    await expectLater(
      client.request('OPTIONS', '/api/test'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.status,
          'network-safe status',
          0,
        ),
      ),
    );
  });
}
