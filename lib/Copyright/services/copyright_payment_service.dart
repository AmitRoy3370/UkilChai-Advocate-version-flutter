// lib/Copyright/services/copyright_payment_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/copyright_payment_model.dart';

class CopyrightPaymentService {
  static String _baseUrl =
      '${BASE_URL.Urls().baseURL}copyright-payment';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==========================================================================
  // 1. CREATE — POST /api/copyright-payment/add
  // ==========================================================================
  static Future<Map<String, dynamic>> addPayment({
    required String userId,
    required CopyrightPaymentModel payment,
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
  // 2. UPDATE — PUT /api/copyright-payment/update/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> updatePayment({
    required String id,
    required String userId,
    required CopyrightPaymentModel payment,
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
  // 3. FIND BY ID — GET /api/copyright-payment/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }

  // ==========================================================================
  // 4. FIND ALL — GET /api/copyright-payment/all
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
  // 6. FIND BY SENDER USER NAME
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySenderUserName(
      String senderUserName) async {
    return _getRequest(
        '$_baseUrl/search/senderUserName?senderUserName=${Uri.encodeComponent(senderUserName)}');
  }

  // ==========================================================================
  // 7. FIND BY SENDER PHONE
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySenderPhoneNumber(
      String senderPhoneNumber) async {
    return _getRequest(
        '$_baseUrl/search/senderPhoneNumber?senderPhoneNumber=${Uri.encodeComponent(senderPhoneNumber)}');
  }

  // ==========================================================================
  // 8. FIND BY TRANSACTION ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTransactionId(
      String transactionId) async {
    return _getRequest(
        '$_baseUrl/search/transactionId?transactionId=${Uri.encodeComponent(transactionId)}');
  }

  // ==========================================================================
  // 9. FIND BY COPYRIGHT ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByCopyrightId(
      String copyrightId) async {
    return _getRequest(
        '$_baseUrl/search/copyrightId?copyrightId=${Uri.encodeComponent(copyrightId)}');
  }

  // ==========================================================================
  // 10. FIND BY COPYRIGHT ID + SENDER USER ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByCopyrightIdAndSenderUserId({
    required String copyrightId,
    required String senderUserId,
  }) async {
    return _getRequest(
        '$_baseUrl/search/copyrightIdAndSenderUserId?copyrightId=${Uri.encodeComponent(copyrightId)}&senderUserId=${Uri.encodeComponent(senderUserId)}');
  }

  // ==========================================================================
  // 11. FIND BY SENDING TIME AFTER
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySendingTimeAfter(
      String isoTime) async {
    return _getRequest(
        '$_baseUrl/search/sendingTime/after?sendingTime=${Uri.encodeComponent(isoTime)}');
  }

  // ==========================================================================
  // 12. FIND BY SENDING TIME BEFORE
  // ==========================================================================
  static Future<Map<String, dynamic>> findBySendingTimeBefore(
      String isoTime) async {
    return _getRequest(
        '$_baseUrl/search/sendingTime/before?sendingTime=${Uri.encodeComponent(isoTime)}');
  }

  // ==========================================================================
  // 13. FIND BY RECEIVER PHONE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByReceiverPhoneNumber(
      String receiverPhoneNumber) async {
    return _getRequest(
        '$_baseUrl/search/receiverPhoneNumber?receiverPhoneNumber=${Uri.encodeComponent(receiverPhoneNumber)}');
  }

  // ==========================================================================
  // 14. FIND BY AMOUNT >=
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAmountGreaterThanEqual(
      double amount) async {
    return _getRequest(
        '$_baseUrl/search/amount/greaterThanEqual?amount=$amount');
  }

  // ==========================================================================
  // 15. FIND BY AMOUNT <=
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAmountLessThanEqual(
      double amount) async {
    return _getRequest('$_baseUrl/search/amount/lessThanEqual?amount=$amount');
  }

  // ==========================================================================
  // 16. DELETE — DELETE /api/copyright-payment/delete/{id}?userId=...
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
  static CopyrightPaymentModel? parseSingle(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return CopyrightPaymentModel.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<CopyrightPaymentModel> parseList(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) =>
              CopyrightPaymentModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}