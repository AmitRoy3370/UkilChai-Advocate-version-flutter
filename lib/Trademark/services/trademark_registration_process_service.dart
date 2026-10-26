// lib/Trademark/services/trademark_registration_process_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/trademark_registration_process_model.dart';

class TrademarkRegistrationProcessService {
  static String _baseUrl =
      '${BASE_URL.Urls().baseURL}trademark-registration-process';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==========================================================================
  // 1. CREATE — POST /api/trademark-registration-process/add?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> addProcess({
    required String userId,
    required TrademarkRegistrationProcessModel process,
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
  // 2. UPDATE — PUT /api/trademark-registration-process/update/{id}?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> updateProcess({
    required String id,
    required String userId,
    required TrademarkRegistrationProcessModel process,
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
  // 3. FIND BY ID — GET /api/trademark-registration-process/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }

  // ==========================================================================
  // 4. FIND ALL — GET /api/trademark-registration-process/all
  // ==========================================================================
  static Future<Map<String, dynamic>> findAll() async {
    return _getRequest('$_baseUrl/all');
  }

  // ==========================================================================
  // 5. FIND BY USER ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByUserId(String userId) async {
    return _getRequest(
        '$_baseUrl/search/userId?userId=${Uri.encodeComponent(userId)}');
  }

  // ==========================================================================
  // 6. FIND BY ADVOCATE ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAdvocateId(
      String advocateId) async {
    return _getRequest(
        '$_baseUrl/search/advocateId?advocateId=${Uri.encodeComponent(advocateId)}');
  }

  // ==========================================================================
  // 7. FIND BY TRADEMARK ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTradeMarkId(
      String tradeMarkId) async {
    return _getRequest(
        '$_baseUrl/search/tradeMarkId?tradeMarkId=${Uri.encodeComponent(tradeMarkId)}');
  }

  // ==========================================================================
  // 8. FIND BY STATUS
  // ==========================================================================
  static Future<Map<String, dynamic>> findByStatus(bool status) async {
    return _getRequest('$_baseUrl/search/status?status=$status');
  }

  // ==========================================================================
  // 9. FIND BY STEPS
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySteps(String steps) async {
    return _getRequest(
        '$_baseUrl/search/steps?steps=${Uri.encodeComponent(steps)}');
  }

  // ==========================================================================
  // 10. FIND BY MULTIPLE TRADEMARK IDS
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTradeMarkIds(
      List<String> ids) async {
    final query = ids
        .where((e) => e.isNotEmpty)
        .map((e) => 'tradeMarkIds=${Uri.encodeComponent(e)}')
        .join('&');
    return _getRequest('$_baseUrl/search/tradeMarkIds?$query');
  }

  // ==========================================================================
  // 11. DELETE — DELETE /api/trademark-registration-process/delete/{id}?userId=...
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
  static TrademarkRegistrationProcessModel? parseSingle(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return TrademarkRegistrationProcessModel.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<TrademarkRegistrationProcessModel> parseList(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => TrademarkRegistrationProcessModel.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// Response DTO parser (with names + nested trademark)
  static List<TrademarkRegistrationProcessResponse> parseListDTO(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => TrademarkRegistrationProcessResponse.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}