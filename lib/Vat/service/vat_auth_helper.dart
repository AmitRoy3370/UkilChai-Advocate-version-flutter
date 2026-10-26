// lib/vat/service/vat_auth_helper.dart

import 'package:shared_preferences/shared_preferences.dart';

class VatAuthHelper {
  static const String _tokenKey = 'jwt_token';

  /// Returns the raw JWT token stored in SharedPreferences.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  /// Returns a `Bearer <token>` header value, or null if no token.
  static Future<String?> getBearerToken() async {
    final token = await getToken();
    if (token == null) return null;
    return 'Bearer $token';
  }

  /// Returns headers suitable for JSON requests.
  static Future<Map<String, String>> jsonHeaders() async {
    final bearer = await getBearerToken();
    return {
      if (bearer != null) 'Authorization': bearer,
      'Content-Type': 'application/json',
    };
  }

  /// Returns headers suitable for GET requests.
  static Future<Map<String, String>> getHeaders() async {
    final bearer = await getBearerToken();
    return {
      if (bearer != null) 'Authorization': bearer,
    };
  }
}