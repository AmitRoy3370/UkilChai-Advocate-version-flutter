// lib/Trademark/services/trademark_payment_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/trademark_payment_model.dart';

class TrademarkPaymentService {
  static String _baseUrl = '${BASE_URL.Urls().baseURL}trademark-payment';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==========================================================================
  // 1. CREATE — POST /api/trademark-payment/add?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> addPayment({
    required String userId,
    required TrademarkPaymentModel payment,
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
  // 2. UPDATE — PUT /api/trademark-payment/update/{id}?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> updatePayment({
    required String id,
    required String userId,
    required TrademarkPaymentModel payment,
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
  // 3. FIND BY ID — GET /api/trademark-payment/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }

  // ==========================================================================
  // 4. FIND ALL — GET /api/trademark-payment/all
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
        '$_baseUrl/search/senderUserId?senderUserId=${Uri.encodeComponent(senderUserId)}');
  }

  // ==========================================================================
  // 6. FIND BY SENDER PHONE
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySenderPhone(
      String senderPhoneNumber) async {
    return _getRequest(
        '$_baseUrl/search/senderPhoneNumber?senderPhoneNumber=${Uri.encodeComponent(senderPhoneNumber)}');
  }

  // ==========================================================================
  // 7. FIND BY RECEIVER PHONE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByReceiverPhone(
      String receiverPhoneNumber) async {
    return _getRequest(
        '$_baseUrl/search/receiverPhoneNumber?receiverPhoneNumber=${Uri.encodeComponent(receiverPhoneNumber)}');
  }

  // ==========================================================================
  // 8. FIND BY SENDER USER ID + TRADEMARK ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySenderUserIdAndTrademarkId({
    required String trademarkId,
    required String senderUserId,
  }) async {
    return _getRequest(
        '$_baseUrl/search/senderUserIdAndTrademarkId?trademarkId=${Uri.encodeComponent(trademarkId)}&senderUserId=${Uri.encodeComponent(senderUserId)}');
  }

  // ==========================================================================
  // 9. FIND BY TRADEMARK ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTrademarkId(
      String trademarkId) async {
    return _getRequest(
        '$_baseUrl/search/trademarkId?trademarkId=${Uri.encodeComponent(trademarkId)}');
  }

  // ==========================================================================
  // 10. FIND BY TRANSACTION ID (exact)
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTransactionId(
      String transactionId) async {
    return _getRequest(
        '$_baseUrl/search/transactionId?transactionId=${Uri.encodeComponent(transactionId)}');
  }

  // ==========================================================================
  // 11. FIND BY TRANSACTION ID (containing)
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTransactionIdContaining(
      String transactionId) async {
    return _getRequest(
        '$_baseUrl/search/transactionId/containing?transactionId=${Uri.encodeComponent(transactionId)}');
  }

  // ==========================================================================
  // 12. FIND BY AMOUNT >=
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAmountGte(double amount) async {
    return _getRequest(
        '$_baseUrl/search/amount/greaterThanEqual?amount=$amount');
  }

  // ==========================================================================
  // 13. FIND BY AMOUNT <=
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAmountLte(double amount) async {
    return _getRequest('$_baseUrl/search/amount/lessThanEqual?amount=$amount');
  }

  // ==========================================================================
  // 14. FIND BY SENDING TIME BEFORE
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySendingTimeBefore(
      String isoTime) async {
    return _getRequest(
        '$_baseUrl/search/sendingTime/before?sendingTime=${Uri.encodeComponent(isoTime)}');
  }

  // ==========================================================================
  // 15. FIND BY SENDING TIME AFTER
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySendingTimeAfter(
      String isoTime) async {
    return _getRequest(
        '$_baseUrl/search/sendingTime/after?sendingTime=${Uri.encodeComponent(isoTime)}');
  }

  // ==========================================================================
  // 16. DELETE — DELETE /api/trademark-payment/delete/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> deletePayment({
    required String id,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/delete/$id');
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
  static TrademarkPaymentResponse? parseSingle(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return TrademarkPaymentResponse.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<TrademarkPaymentResponse> parseList(
      Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => TrademarkPaymentResponse.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}