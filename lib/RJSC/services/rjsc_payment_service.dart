// lib/RJSC/services/rjsc_payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Auth/AuthService.dart';
import '../models/rjsc_payment_model.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

class RjscPaymentService {
  static String _baseUrl =
      '${BASE_URL.Urls().baseURL}rjsc-payment';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ==================== CREATE ====================
  static Future<Map<String, dynamic>> addPayment({
    required String userId,
    required RjscPaymentModel payment,
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

  // ==================== UPDATE ====================
  static Future<Map<String, dynamic>> updatePayment({
    required String id,
    required String userId,
    required RjscPaymentModel payment,
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

  // ==================== FIND BY ID ====================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }

  // ==================== FIND ALL ====================
  static Future<Map<String, dynamic>> findAll() async {
    return _getRequest('$_baseUrl/all');
  }

  // ==================== FIND BY SENDER USER ID ====================
  static Future<Map<String, dynamic>> findBySenderUserId(
      String senderUserId) async {
    return _getRequest('$_baseUrl/search/senderUserId?senderUserId=$senderUserId');
  }

  // ==================== FIND BY SENDER USER NAME ====================
  static Future<Map<String, dynamic>> findBySenderUserName(
      String senderUserName) async {
    return _getRequest(
        '$_baseUrl/search/senderUserName?senderUserName=$senderUserName');
  }

  // ==================== FIND BY SENDER PHONE ====================
  static Future<Map<String, dynamic>> findBySenderPhoneNumber(
      String phone) async {
    return _getRequest(
        '$_baseUrl/search/senderPhoneNumber?senderPhoneNumber=$phone');
  }

  // ==================== FIND BY RECEIVER PHONE ====================
  static Future<Map<String, dynamic>> findByReceiverPhoneNumber(
      String phone) async {
    return _getRequest(
        '$_baseUrl/search/receiverPhoneNumber?receiverPhoneNumber=$phone');
  }

  // ==================== FIND BY TRANSACTION ID (EXACT) ====================
  static Future<Map<String, dynamic>> findByTransactionId(
      String transactionId) async {
    return _getRequest(
        '$_baseUrl/search/transactionId?transactionId=$transactionId');
  }

  // ==================== FIND BY TRANSACTION ID (CONTAINING) ====================
  static Future<Map<String, dynamic>> findByTransactionIdContaining(
      String transactionId) async {
    return _getRequest(
        '$_baseUrl/search/transactionId/containing?transactionId=$transactionId');
  }

  // ==================== FIND BY AMOUNT >= ====================
  static Future<Map<String, dynamic>> findByAmountGreaterThanEqual(
      double amount) async {
    return _getRequest('$_baseUrl/search/amount/greaterThanEqual?amount=$amount');
  }

  // ==================== FIND BY AMOUNT <= ====================
  static Future<Map<String, dynamic>> findByAmountLessThanEqual(
      double amount) async {
    return _getRequest('$_baseUrl/search/amount/lessThanEqual?amount=$amount');
  }

  // ==================== FIND BY SENDING TIME AFTER ====================
  static Future<Map<String, dynamic>> findBySendingTimeAfter(
      String isoTime) async {
    return _getRequest('$_baseUrl/search/sendingTime/after?sendingTime=$isoTime');
  }

  // ==================== FIND BY SENDING TIME BEFORE ====================
  static Future<Map<String, dynamic>> findBySendingTimeBefore(
      String isoTime) async {
    return _getRequest('$_baseUrl/search/sendingTime/before?sendingTime=$isoTime');
  }

  // ==================== FIND BY SENDER USER ID + RJSC ID ====================
  static Future<Map<String, dynamic>> findBySenderUserIdAndRjscId({
    required String senderUserId,
    required String rjscId,
  }) async {
    return _getRequest(
        '$_baseUrl/search/senderUserIdAndRjscId?senderUserId=$senderUserId&rjscId=$rjscId');
  }

  // ==================== FIND BY RJSC ID ====================
  static Future<Map<String, dynamic>> findByRjscId(String rjscId) async {
    return _getRequest('$_baseUrl/search/rjscId?rjscId=$rjscId');
  }

  // ==================== DELETE ====================
  static Future<Map<String, dynamic>> deletePayment({
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
  static RjscPaymentModel? parseSingle(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return RjscPaymentModel.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<RjscPaymentModel> parseList(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => RjscPaymentModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}