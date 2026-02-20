import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as baseURL;

class AuthService {
  static const String tokenKey = "jwt_token";

  static ValueNotifier<String?> userIdNotifier = ValueNotifier(null);

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("userId", userId);
    userIdNotifier.value = userId;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    String allAdvocateURL = "${baseURL.Urls().baseURL}advocate/all";

    Uri uri = Uri.parse(allAdvocateURL);

    var response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (kDebugMode) {
      print("response status code :- ${response.statusCode}");
    }

    if (response.statusCode == 403) {
      return false;
    }

    return true;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove("userId");
    userIdNotifier.value = null;
  }
}