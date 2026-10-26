// lib/RJSC/services/rjsc_registration_process_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Auth/AuthService.dart';
import '../models/rjsc_registration_process_model.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

class RjscRegistrationProcessService {
  static String _baseUrl =
      '${BASE_URL.Urls().baseURL}rjsc-registration-process';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==================== CREATE ====================
  static Future<Map<String, dynamic>> addProcess({
    required String userId,
    required RjscRegistrationProcessModel process,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/add?userId=$userId');
      final headers = await _authHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(process.toJson()),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== UPDATE ====================
  static Future<Map<String, dynamic>> updateProcess({
    required String id,
    required String userId,
    required RjscRegistrationProcessModel process,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/update/$id?userId=$userId');
      final headers = await _authHeaders();

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(process.toJson()),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== FIND BY ID ====================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }

  // ==================== FIND ALL ====================
  static Future<Map<String, dynamic>> findAll() async {
    return _getRequest('$_baseUrl/all');
  }

  // ==================== FIND BY USER ID ====================
  static Future<Map<String, dynamic>> findByUserId(String userId) async {
    return _getRequest('$_baseUrl/search/userId?userId=$userId');
  }

  // ==================== FIND BY ADVOCATE ID ====================
  static Future<Map<String, dynamic>> findByAdvocateId(
      String advocateId) async {
    return _getRequest('$_baseUrl/search/advocateId?advocateId=$advocateId');
  }

  // ==================== FIND BY STATUS ====================
  static Future<Map<String, dynamic>> findByStatus(bool status) async {
    return _getRequest('$_baseUrl/search/status?status=$status');
  }

  // ==================== FIND BY RJSC ID ====================
  static Future<Map<String, dynamic>> findByRjscId(String rjscId) async {
    return _getRequest('$_baseUrl/search/rjscId?rjscId=$rjscId');
  }

  // ==================== FIND BY RJSC IDs (BULK) ====================
  static Future<Map<String, dynamic>> findByRjscIdIn(
      List<String> rjscIds) async {
    final query = rjscIds.map((id) => 'rjscIds=$id').join('&');
    return _getRequest('$_baseUrl/search/rjscIds?$query');
  }

  // ==================== FIND BY STEPS ====================
  static Future<Map<String, dynamic>> findBySteps(String steps) async {
    return _getRequest('$_baseUrl/search/steps?steps=$steps');
  }

  // ==================== DELETE ====================
  static Future<Map<String, dynamic>> deleteProcess({
    required String id,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/delete/$id?userId=$userId');
      final headers = await _authHeaders();

      final response = await http.delete(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== HELPERS ====================
  static Future<Map<String, dynamic>> _getRequest(String url) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
      return {'status': 'error', 'message': 'Unexpected response format'};
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to parse response: ${response.body}',
      };
    }
  }

  // ==================== PARSERS ====================
  static RjscRegistrationProcessResponseDTO? parseSingle(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return RjscRegistrationProcessResponseDTO.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<RjscRegistrationProcessResponseDTO> parseList(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => RjscRegistrationProcessResponseDTO.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}