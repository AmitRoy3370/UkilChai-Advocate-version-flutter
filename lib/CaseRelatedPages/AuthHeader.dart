import 'package:shared_preferences/shared_preferences.dart';

class AuthHeader {
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    return {
      'Authorization': 'Bearer $token',
    };
  }
}
