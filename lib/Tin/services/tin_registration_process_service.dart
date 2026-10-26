// lib/Tin/services/tin_registration_process_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/tin_registration_process_model.dart';

class TinRegistrationProcessService {
  static String _baseUrl = '${BASE_URL.Urls().baseURL}tin-registration';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==========================================================================
  // 1. CREATE — POST /api/tin-registration/add?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> addProcess({
    required String userId,
    required TinRegistrationProcessModel process,
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

  // ==========================================================================
  // 2. UPDATE — PUT /api/tin-registration/update/{id}?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> updateProcess({
    required String id,
    required String userId,
    required TinRegistrationProcessModel process,
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

  // ==========================================================================
  // 3. FIND BY ID — GET /api/tin-registration/{id}
  // ==========================================================================
static Future<Map<String, dynamic>> findByTinId(String tinId) async {
  try {
    final uri = Uri.parse(
        '$_baseUrl/search/tin?tinId=${Uri.encodeComponent(tinId)}');
    final headers = await _authHeaders();
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  } catch (e) {
    return {'status': 'error', 'message': 'Network error: $e'};
  }
}

static TinRegistrationProcessDTO? parseSingleDTO(
    Map<String, dynamic> json) {
  if (json['status'] == 'success' && json['data'] != null) {
    return TinRegistrationProcessDTO.fromJson(
        Map<String, dynamic>.from(json['data']));
  }
  return null;
}

  // ==========================================================================
  // 4. FIND ALL — GET /api/tin-registration/all
  // ==========================================================================
  static Future<Map<String, dynamic>> findAll() async {
    return _getRequest('$_baseUrl/all');
  }

  // ==========================================================================
  // 5. FIND BY CENTER ADMIN ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByCenterAdminId(
      String centerAdminId) async {
    return _getRequest(
        '$_baseUrl/search/center-admin?centerAdminId=${Uri.encodeComponent(centerAdminId)}');
  }

  // ==========================================================================
  // 6. FIND BY ADVOCATE ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAdvocateId(
      String advocateId) async {
    return _getRequest(
        '$_baseUrl/search/advocate?advocateId=${Uri.encodeComponent(advocateId)}');
  }

  // ==========================================================================
  // 7. FIND BY TIN ID
  // ==========================================================================
  /*static Future<Map<String, dynamic>> findByTinId(String tinId) async {
    return _getRequest(
        '$_baseUrl/search/tin?tinId=${Uri.encodeComponent(tinId)}');
  }*/

  // ==========================================================================
  // 8. FIND BY STEPS
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySteps(String steps) async {
    return _getRequest(
        '$_baseUrl/search/steps?steps=${Uri.encodeComponent(steps)}');
  }

  // ==========================================================================
  // 9. DELETE — DELETE /api/tin-registration/delete/{id}?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> deleteProcess({
    required String id,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/delete/$id?userId=${Uri.encodeComponent(userId)}');
      final headers = await _authHeaders();
      final response = await http.delete(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // INTERNAL HELPERS
  // ==========================================================================
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

  // ==========================================================================
  // TYPED PARSERS
  // ==========================================================================
  static TinRegistrationProcessModel? parseSingle(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return TinRegistrationProcessModel.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<TinRegistrationProcessModel> parseList(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => TinRegistrationProcessModel.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// Response DTO parser (with names + nested TIN)
  static List<TinRegistrationProcessDTO> parseListDTO(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) =>
              TinRegistrationProcessDTO.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}