import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Utils/BaseURL.dart' as BASE_URL;

class UserActiveService {
  static String baseUrl = "${BASE_URL.Urls().baseURL}user-active";

  // ================= ADD ACTIVE =================
  static Future<void> addUserActive(String userId, bool active, String? token) async {

    print("uri :- $baseUrl/add");

    final response = await http.post(
      Uri.parse("$baseUrl/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "userId": userId,
        "active": active,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception(response.body);
    }
  }

  // ================= UPDATE ACTIVE =================
  static Future<void> updateUserActive(
      String id, String userId, bool active, String? token) async {

    print("uri in user active service :- $baseUrl/update/$id/$userId");

    final response = await http.put(
      Uri.parse("$baseUrl/update/$id/$userId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "userId": userId,
        "active": active,
      }),
    ).timeout(const Duration(seconds: 10));

    print("update response status :- ${response.statusCode}");

    if (response.statusCode != 200) {

      print("I am throwing exception in the update user active service....");

      throw Exception(response.body);
    }
  }

  // ================= FIND BY USER =================
  static Future<Map<String, dynamic>> findByUserId(String userId, String? token) async {
    final response =
    await http.get(Uri.parse("$baseUrl/user/$userId")
    , headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  static Future<void> setActive(String userId, bool active, String? token) async {

    print("uri :- $baseUrl/add");

    final response = await http.post(
      Uri.parse("$baseUrl/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "userId": userId,
        "active": active,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception(response.body);
    }

  }

}
