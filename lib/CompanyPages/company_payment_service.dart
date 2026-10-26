// lib/CompanyPages/company_payment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../CompanyPages/company_request_payment.dart';
import '../CompanyPages/company_payment_response.dart';
import '../Utils/BaseURL.dart' as baseURL;

class CompanyPaymentService {
  final String baseUrl = baseURL.Urls().baseURL;
  String? _token;

  CompanyPaymentService({String? token}) {
    _token = token;
  }

  Future<String?> _getToken() async {
    if (_token != null && _token!.isNotEmpty) {
      return _token;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('jwt_token');
      return _token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ==================== ADD PAYMENT ====================
  Future<CompanyRequestPayment> addPayment({
    required CompanyRequestPayment payment,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/add');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(payment.toJson()),
    );

    print('Add Payment Status: ${response.statusCode}');
    print('Add Payment Response: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyRequestPayment.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to add payment: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== UPDATE PAYMENT ====================
  Future<CompanyRequestPayment> updatePayment({
    required String id,
    required CompanyRequestPayment payment,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/update/$id');
    final response = await http.put(
      uri,
      headers: {
        ..._headers,
        'userId': userId,
      },
      body: jsonEncode(payment.toJson()),
    );

    print('Update Payment Status: ${response.statusCode}');
    print('Update Payment Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyRequestPayment.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to update payment: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== GET PAYMENT BY ID ====================
  Future<CompanyPaymentResponse> getPaymentById(String id) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/$id');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyPaymentResponse.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Payment not found');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payment: ${response.statusCode}');
    }
  }

  // ==================== GET ALL PAYMENTS ====================
  Future<List<CompanyPaymentResponse>> getAllPayments() async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/all');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyPaymentResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  // ==================== GET PAYMENTS BY COMPANY ID ====================
  Future<List<CompanyPaymentResponse>> getPaymentsByCompanyId(String companyId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/company/$companyId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyPaymentResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  // ==================== GET PAYMENTS BY SENDER USER ID ====================
  Future<List<CompanyPaymentResponse>> getPaymentsBySenderUserId(String senderUserId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/sender/user/$senderUserId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyPaymentResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  // ==================== GET PAYMENTS BY SENDER PHONE ====================
  Future<List<CompanyPaymentResponse>> getPaymentsBySenderPhone(String senderPhoneNumber) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/sender/phone/$senderPhoneNumber');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyPaymentResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  // ==================== GET PAYMENTS BY RECEIVER PHONE ====================
  Future<List<CompanyPaymentResponse>> getPaymentsByReceiverPhone(String receiverPhoneNumber) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/receiver/phone/$receiverPhoneNumber');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyPaymentResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  // ==================== GET PAYMENTS BY TRANSACTION ID ====================
  Future<List<CompanyPaymentResponse>> getPaymentsByTransactionId(String transactionId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/transaction/$transactionId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyPaymentResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  // ==================== GET PAYMENTS BY AMOUNT (GTE) ====================
  Future<List<CompanyPaymentResponse>> getPaymentsByAmountGte(double amount) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/amount/gte?amount=$amount');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyPaymentResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  // ==================== GET PAYMENTS BY AMOUNT (LTE) ====================
  Future<List<CompanyPaymentResponse>> getPaymentsByAmountLte(double amount) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/amount/lte?amount=$amount');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyPaymentResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  // ==================== GET PAYMENTS BY TIME AFTER ====================
  Future<List<CompanyPaymentResponse>> getPaymentsByTimeAfter(DateTime time) async {
    await _getToken();

    final isoTime = time.toUtc().toIso8601String();
    final uri = Uri.parse('${baseUrl}company-payments/time/after?sendingTime=$isoTime');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyPaymentResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  // ==================== GET PAYMENTS BY TIME BEFORE ====================
  Future<List<CompanyPaymentResponse>> getPaymentsByTimeBefore(DateTime time) async {
    await _getToken();

    final isoTime = time.toUtc().toIso8601String();
    final uri = Uri.parse('${baseUrl}company-payments/time/before?sendingTime=$isoTime');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyPaymentResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode}');
    }
  }

  // ==================== DELETE PAYMENT ====================
  Future<bool> deletePayment({
    required String id,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-payments/delete/$id');
    final response = await http.delete(
      uri,
      headers: {
        ..._headers,
        'userId': userId,
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      return false;
    }
  }
}