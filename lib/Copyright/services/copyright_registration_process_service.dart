// lib/Copyright/services/copyright_registration_process_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/copyright_registration_process_model.dart';

class CopyrightRegistrationProcessService {
  static String _baseUrl =
      '${BASE_URL.Urls().baseURL}copyright-process';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==========================================================================
  // 1. CREATE — POST /api/copyright-process/add
  // ==========================================================================
  static Future<Map<String, dynamic>> addProcess({
    required String userId,
    required CopyrightRegistrationProcessModel process,
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
  // 2. UPDATE — PUT /api/copyright-process/update/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> updateProcess({
    required String id,
    required String userId,
    required CopyrightRegistrationProcessModel process,
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
  // 3. FIND BY ID — GET /api/copyright-process/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }

  // ==========================================================================
  // 4. FIND ALL — GET /api/copyright-process/all
  // ==========================================================================
  static Future<Map<String, dynamic>> findAll() async {
    return _getRequest('$_baseUrl/all');
  }

  // ==========================================================================
  // 5. FIND BY COPYRIGHT ID — GET /api/copyright-process/search/copyrightId
  // ==========================================================================
  static Future<Map<String, dynamic>> findByCopyrightId(
      String copyrightId) async {
    return _getRequest(
        '$_baseUrl/search/copyrightId?copyrightId=${Uri.encodeComponent(copyrightId)}');
  }

  // ==========================================================================
  // 6. FIND BY USER ID — GET /api/copyright-process/search/userId
  // ==========================================================================
  static Future<Map<String, dynamic>> findByUserId(String userId) async {
    return _getRequest(
        '$_baseUrl/search/userId?userId=${Uri.encodeComponent(userId)}');
  }

  // ==========================================================================
  // 7. FIND BY ADVOCATE ID — GET /api/copyright-process/search/advocateId
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAdvocateId(
      String advocateId) async {
    return _getRequest(
        '$_baseUrl/search/advocateId?advocateId=${Uri.encodeComponent(advocateId)}');
  }

  // ==========================================================================
  // 8. FIND BY STEPS — GET /api/copyright-process/search/steps
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySteps(String steps) async {
    return _getRequest(
        '$_baseUrl/search/steps?steps=${Uri.encodeComponent(steps)}');
  }

  // ==========================================================================
  // 9. FIND BY STATUS — GET /api/copyright-process/search/status
  // ==========================================================================
  static Future<Map<String, dynamic>> findByStatus(bool status) async {
    return _getRequest('$_baseUrl/search/status?status=$status');
  }

  // ==========================================================================
  // 10. DELETE — DELETE /api/copyright-process/delete/{id}?userId=...
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
  static CopyrightRegistrationProcessResponseDTO? parseSingle(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return CopyrightRegistrationProcessResponseDTO.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<CopyrightRegistrationProcessResponseDTO> parseList(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => CopyrightRegistrationProcessResponseDTO.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}