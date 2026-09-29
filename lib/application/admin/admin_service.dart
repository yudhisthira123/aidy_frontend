import '../../domain/gateways/lokale_api.dart';

final class AdminSnapshot {
  const AdminSnapshot({
    required this.stats,
    required this.users,
    required this.requests,
    required this.equipment,
    required this.categories,
  });

  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> requests;
  final List<Map<String, dynamic>> equipment;
  final List<Map<String, dynamic>> categories;
}

final class AdminService {
  AdminService(this._api);

  final LokaleApi _api;

  Future<AdminSnapshot> load() async {
    final results = await Future.wait([
      _api.request('GET', '/api/admin/stats'),
      _api.request('GET', '/api/admin/users'),
      _api.request('GET', '/api/admin/requests'),
      _api.request('GET', '/api/admin/equipment'),
      _api.request('GET', '/api/admin/categories'),
    ]);
    return AdminSnapshot(
      stats: _map(results[0], 'stats'),
      users: _list(results[1], 'users'),
      requests: _list(results[2], 'requests'),
      equipment: _list(results[3], 'equipment'),
      categories: _list(results[4], 'categories'),
    );
  }

  Future<void> saveUser(Map<String, dynamic> body, {String? id}) async {
    await _api.request(
      id == null ? 'POST' : 'PATCH',
      id == null ? '/api/admin/users' : '/api/admin/users/$id',
      body: body,
    );
  }

  Future<void> changeUserRole(String id, String role) =>
      saveUser({'role': role}, id: id);

  Future<void> saveEquipment(Map<String, dynamic> body, {String? id}) async {
    await _api.request(
      id == null ? 'POST' : 'PUT',
      id == null ? '/api/admin/equipment' : '/api/admin/equipment/$id',
      body: body,
    );
  }

  Future<void> saveCategory(Map<String, dynamic> body, {String? id}) async {
    await _api.request(
      id == null ? 'POST' : 'PUT',
      id == null ? '/api/admin/categories' : '/api/admin/categories/$id',
      body: body,
    );
  }

  Future<void> addSubcategory(
    String categoryId,
    Map<String, dynamic> body,
  ) async {
    await _api.request(
      'POST',
      '/api/admin/categories/$categoryId/subcategories',
      body: body,
    );
  }

  Future<void> updateRequestStatus(String id, String status) async {
    await _api.request(
      'PATCH',
      '/api/admin/requests/$id',
      body: {'status': status},
    );
  }

  Future<void> delete(AdminResource resource, String id) async {
    await _api.request('DELETE', '/api/admin/${resource.path}/$id');
  }

  Future<void> deleteSubcategory(
    String categoryId,
    String subcategoryId,
  ) async {
    await _api.request(
      'DELETE',
      '/api/admin/categories/$categoryId/subcategories/$subcategoryId',
    );
  }

  Map<String, dynamic> _map(dynamic envelope, String key) =>
      Map<String, dynamic>.from(envelope[key] as Map? ?? const {});

  List<Map<String, dynamic>> _list(dynamic envelope, String key) =>
      (envelope[key] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
}

enum AdminResource {
  users('users'),
  requests('requests'),
  equipment('equipment'),
  categories('categories');

  const AdminResource(this.path);
  final String path;
}
