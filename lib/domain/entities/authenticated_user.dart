final class AuthenticatedUser {
  AuthenticatedUser._(this.data);

  final Map<String, dynamic> data;

  String get id => (data['_id'] ?? data['id'] ?? '').toString();
  String get name => (data['name'] ?? '').toString();
  String get email => (data['email'] ?? '').toString();
  bool get isAdmin => data['role'] == 'admin' || data['isAdmin'] == true;
  String get onboardingStatus =>
      ((data['onboarding'] as Map?)?['status'] ?? 'incomplete').toString();

  factory AuthenticatedUser.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('User response is missing.');
    }
    final data = Map<String, dynamic>.from(value);
    final id = (data['_id'] ?? data['id'])?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('User identifier is missing.');
    }
    return AuthenticatedUser._(Map.unmodifiable(data));
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
