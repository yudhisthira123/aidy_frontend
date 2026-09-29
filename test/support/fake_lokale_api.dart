import 'package:aidy_mobile/domain/entities/aidy_request.dart';
import 'package:aidy_mobile/domain/gateways/lokale_api.dart';

final class RecordedRequest {
  const RecordedRequest(this.method, this.path, this.body);

  final String method;
  final String path;
  final Object? body;
}

final class FakeLokaleApi implements LokaleApi {
  @override
  String get baseUrl => 'https://example.test';

  @override
  String? token;

  @override
  String language = 'en';

  @override
  void Function()? onUnauthorized;

  final List<RecordedRequest> requests = [];
  List<AidyRequestModel> requestModels = [];
  dynamic response;
  Object? error;
  Future<dynamic> Function(String method, String path, Object? body)? handler;
  bool restored = false;
  bool cleared = false;

  String? get method => requests.lastOrNull?.method;
  String? get path => requests.lastOrNull?.path;
  Object? get body => requests.lastOrNull?.body;

  @override
  Future<void> clearToken() async {
    token = null;
    cleared = true;
  }

  @override
  Future<List<AidyRequestModel>> getRequests({
    int limit = 50,
    String? cursor,
  }) async => requestModels;

  @override
  Future<String?> readLocal(String key) async => null;

  @override
  Future<dynamic> request(String method, String path, {Object? body}) async {
    requests.add(RecordedRequest(method, path, body));
    if (error case final failure?) throw failure;
    return handler?.call(method, path, body) ?? response;
  }

  @override
  Future<void> restore() async => restored = true;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> writeLocal(String key, String value) async {}
}
