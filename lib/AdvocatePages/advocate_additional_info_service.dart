import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'advocate_additional_info_model.dart';

class AdvocateAdditionalInfoService {
  // Helper method to get the token
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? '';
  }

  // Helper method for headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ==================== ADD ====================
  static Future<AdvocateAdditionalInfo> addAdditionalInfo(
      AdvocateAdditionalInfo info, String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-additional-info/add/$userId");
    final headers = await _getHeaders();

    final response = await http.post(url, headers: headers, body: jsonEncode(info.toJson()));

    if (response.statusCode == 201) {
      return AdvocateAdditionalInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== UPDATE ====================
  static Future<AdvocateAdditionalInfo> updateAdditionalInfo(
      AdvocateAdditionalInfo info, String id, String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-additional-info/update/$id/$userId");
    final headers = await _getHeaders();

    final response = await http.put(url, headers: headers, body: jsonEncode(info.toJson()));

    if (response.statusCode == 200) {
      return AdvocateAdditionalInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY ID ====================
  static Future<AdvocateAdditionalInfo> findById(String id) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-additional-info/$id");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return AdvocateAdditionalInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND ALL ====================
  static Future<List<AdvocateAdditionalInfo>> findAll() async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-additional-info/all");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateAdditionalInfo.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY ADVOCATE ID ====================
  static Future<AdvocateAdditionalInfo> findByAdvocateId(String advocateId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-additional-info/advocate/$advocateId");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return AdvocateAdditionalInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY ADDRESS ====================
  static Future<List<AdvocateAdditionalInfo>> searchByAddress(String address) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-additional-info/address/$address");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateAdditionalInfo.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY CITY ====================
  static Future<List<AdvocateAdditionalInfo>> searchByCity(String city) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-additional-info/city/$city");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateAdditionalInfo.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY NID (Exact) ====================
  static Future<AdvocateAdditionalInfo> findByNid(String nidNumber) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-additional-info/nid/$nidNumber");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return AdvocateAdditionalInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY WHATSAPP ====================
  static Future<AdvocateAdditionalInfo> findByWhatsApp(String whatsAppNumber) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-additional-info/whatsapp/$whatsAppNumber");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return AdvocateAdditionalInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== DELETE ====================
  static Future<bool> deleteAdditionalInfo(String id, String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-additional-info/delete/$id/$userId");
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      return true; // "Additional info removed successfully"
    } else {
      throw Exception(_parseError(response));
    }
  }

  // Helper method to extract error messages from the backend
  static String _parseError(http.Response response) {
    try {
      // If the backend returns a plain string like "No such user find at here..."
      return response.body;
    } catch (e) {
      return "Error: ${response.statusCode}";
    }
  }
}