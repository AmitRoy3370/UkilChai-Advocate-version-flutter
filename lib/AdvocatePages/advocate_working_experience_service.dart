import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'advocate_working_experience_model.dart';

class AdvocateWorkingExperienceService {
  // Helper to get the token
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? '';
  }

  // Helper for JSON headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ==================== ADD ====================
  static Future<AdvocateWorkingExperience> addExperience(
      AdvocateWorkingExperience experience, String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/add/$userId");
    final headers = await _getHeaders();

    final response = await http.post(url, headers: headers, body: jsonEncode(experience.toJson()));

    if (response.statusCode == 201) {
      return AdvocateWorkingExperience.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== UPDATE ====================
  static Future<AdvocateWorkingExperience> updateExperience(
      AdvocateWorkingExperience experience, String id, String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/update/$id/$userId");
    final headers = await _getHeaders();

    final response = await http.put(url, headers: headers, body: jsonEncode(experience.toJson()));

    if (response.statusCode == 200) {
      return AdvocateWorkingExperience.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY ID ====================
  static Future<AdvocateWorkingExperience> findById(String id) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/$id");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return AdvocateWorkingExperience.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND ALL ====================
  static Future<List<AdvocateWorkingExperience>> findAll() async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/all");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateWorkingExperience.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY ADVOCATE ID ====================
  static Future<AdvocateWorkingExperience> findByAdvocateId(String advocateId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/advocate/$advocateId");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return AdvocateWorkingExperience.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY BAR ASSOCIATION ====================
  static Future<List<AdvocateWorkingExperience>> searchByBarAssociation(String barAssociation) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/bar-association/$barAssociation");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateWorkingExperience.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY PRIMARY PRACTICE ====================
  static Future<List<AdvocateWorkingExperience>> searchByPrimaryPractice(String practice) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/primary-practice/$practice");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateWorkingExperience.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY CHAMBER NAME ====================
  static Future<List<AdvocateWorkingExperience>> searchByChamber(String chamberName) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/chamber/$chamberName");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateWorkingExperience.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY LEGAL PRACTICE YEARS (>=) ====================
  static Future<List<AdvocateWorkingExperience>> findByLegalPracticeGte(int years) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/legal-practice/gte?yearOfLegalPractice=$years");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateWorkingExperience.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY PROFESSIONAL EXPERIENCE (>=) ====================
  static Future<List<AdvocateWorkingExperience>> findByProfessionalExperienceGte(int years) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/professional-experience/gte?professionalExperience=$years");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateWorkingExperience.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== DELETE ====================
  static Future<bool> deleteExperience(String id, String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-working-experience/delete/$id/$userId");
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(_parseError(response));
    }
  }

  // Helper method to extract error messages from the backend
  static String _parseError(http.Response response) {
    try {
      return response.body;
    } catch (e) {
      return "Error: ${response.statusCode}";
    }
  }
}