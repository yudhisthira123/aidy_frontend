import 'dart:convert';

import 'package:frontend/common/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {

  final String _keyAuthResponse = 'auth_response';

  SecureStorage._internal();
  static final SecureStorage _secureStorage = SecureStorage._internal();
  factory SecureStorage() => _secureStorage;

  Future setAuthResponse(AuthResponse authResponse) async {
    final pref = await SharedPreferences.getInstance();
    String auth = jsonEncode(authResponse.toJson());
    pref.setString(_keyAuthResponse, auth);
  }

  Future<AuthResponse?> getAuthResponse() async {
    AuthResponse? authResponse;

    final pref = await SharedPreferences.getInstance();
    final String? auth = pref.getString(_keyAuthResponse);

    if(auth != null) {
      authResponse = AuthResponse.fromJson(jsonDecode(auth));
    }
    return authResponse;
  }

}