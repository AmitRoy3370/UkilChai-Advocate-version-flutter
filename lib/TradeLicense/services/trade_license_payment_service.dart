// lib/TradeLicense/services/trade_license_payment_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/trade_license_payment_model.dart';

class TradeLicensePaymentService {
  static String _baseUrl =
      '${BASE_URL.Urls().baseURL}trade-license-payment';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==========================================================================
  // 1. CREATE — POST /api/trade-license-payment/add?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> addPayment({
    required String userId,
    required TradeLicensePaymentModel payment,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/add?userId=$userId');
      final headers = await _authHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payment.toJson()),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 2. UPDATE — PUT /api/trade-license-payment/update/{id}?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> updatePayment({
    required String id,
    required String userId,
    required TradeLicensePaymentModel payment,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/update/$id?userId=$userId');
      final headers = await _authHeaders();

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(payment.toJson()),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 3. FIND BY ID — GET /api/trade-license-payment/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }

  // ==========================================================================
  // 4. FIND ALL — GET /api/trade-license-payment/all
  // ==========================================================================
  static Future<Map<String, dynamic>> findAll() async {
    return _getRequest('$_baseUrl/all');
  }

  // ==========================================================================
  // 5. FIND BY SENDER USER ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySenderUserId(
      String senderUserId) async {
    return _getRequest(
        '$_baseUrl/search/sender-user?senderUserId=${Uri.encodeComponent(senderUserId)}');
  }

  // ==========================================================================
  // 6. FIND BY SENDER PHONE
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySenderPhone(
      String senderPhoneNumber) async {
    return _getRequest(
        '$_baseUrl/search/sender-phone?senderPhoneNumber=${Uri.encodeComponent(senderPhoneNumber)}');
  }

  // ==========================================================================
  // 7. FIND BY RECEIVER PHONE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByReceiverPhone(
      String receiverPhoneNumber) async {
    return _getRequest(
        '$_baseUrl/search/receiver-phone?receiverPhoneNumber=${Uri.encodeComponent(receiverPhoneNumber)}');
  }

  // ==========================================================================
  // 8. FIND BY TRANSACTION ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTransactionId(
      String transactionId) async {
    return _getRequest(
        '$_baseUrl/search/transaction?transactionId=${Uri.encodeComponent(transactionId)}');
  }

  // ==========================================================================
  // 9. FIND BY AMOUNT >=
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAmountGte(double amount) async {
    return _getRequest('$_baseUrl/search/amount-gte?amount=$amount');
  }

  // ==========================================================================
  // 10. FIND BY AMOUNT <=
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAmountLte(double amount) async {
    return _getRequest('$_baseUrl/search/amount-lte?amount=$amount');
  }

  // ==========================================================================
  // 11. FIND BY TRADE LICENSE ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTradeLicenseId(
      String tradeLicenseId) async {
    return _getRequest(
        '$_baseUrl/search/trade-license?tradeLicenseId=${Uri.encodeComponent(tradeLicenseId)}');
  }

  // ==========================================================================
  // 12. FIND BY SENDING TIME BEFORE
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySendingTimeBefore(
      String isoTime) async {
    return _getRequest(
        '$_baseUrl/search/time-before?sendingTime=${Uri.encodeComponent(isoTime)}');
  }

  // ==========================================================================
  // 13. FIND BY SENDING TIME AFTER
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySendingTimeAfter(
      String isoTime) async {
    return _getRequest(
        '$_baseUrl/search/time-after?sendingTime=${Uri.encodeComponent(isoTime)}');
  }

  // ==========================================================================
  // 14. DELETE — DELETE /api/trade-license-payment/delete/{id}?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> deletePayment({
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
  static TradeLicensePaymentResponseDTO? parseSingle(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return TradeLicensePaymentResponseDTO.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<TradeLicensePaymentResponseDTO> parseList(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => TradeLicensePaymentResponseDTO.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}