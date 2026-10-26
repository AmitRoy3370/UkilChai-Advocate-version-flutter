// lib/vat/service/vat_payment_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/vat_payment_model.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;
import 'vat_auth_helper.dart';   // ✅ NEW

class VatPaymentService {
  static String get _baseUrl => BASE_URL.Urls().baseURL;

  // ============================================================
  // CREATE
  // ============================================================
  static Future<VatPaymentModel> addPayment({
    required VatPaymentModel payment,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/add?userId=${Uri.encodeQueryComponent(userId)}');

    final headers = await VatAuthHelper.jsonHeaders();   // ✅ JWT + JSON
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(payment.toJson()),
    );

    final json = _handleResponse(response);
    return VatPaymentModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // UPDATE
  // ============================================================
  static Future<VatPaymentModel> updatePayment({
    required String id,
    required VatPaymentModel payment,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/update/$id?userId=${Uri.encodeQueryComponent(userId)}');

    final headers = await VatAuthHelper.jsonHeaders();   // ✅ JWT + JSON
    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(payment.toJson()),
    );

    final json = _handleResponse(response);
    return VatPaymentModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // READ — By ID
  // ============================================================
  static Future<VatPaymentModel> findById(String id) async {
    final uri = Uri.parse('${_baseUrl}vat-payment/$id');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    return VatPaymentModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // READ — All
  // ============================================================
  static Future<List<VatPaymentModel>> findAll() async {
    final uri = Uri.parse('${_baseUrl}vat-payment/all');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Sender User ID
  // ============================================================
  static Future<List<VatPaymentModel>> findBySenderUserId(
      String senderUserId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/senderUserId?senderUserId=${Uri.encodeQueryComponent(senderUserId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Sender Phone Number
  // ============================================================
  static Future<List<VatPaymentModel>> findBySenderPhoneNumber(
      String senderPhoneNumber) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/senderPhoneNumber?senderPhoneNumber=${Uri.encodeQueryComponent(senderPhoneNumber)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Receiver Phone Number
  // ============================================================
  static Future<List<VatPaymentModel>> findByReceiverPhoneNumber(
      String receiverPhoneNumber) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/receiverPhoneNumber?receiverPhoneNumber=${Uri.encodeQueryComponent(receiverPhoneNumber)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By VAT ID
  // ============================================================
  static Future<List<VatPaymentModel>> findByVatId(String vatId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/vatId?vatId=${Uri.encodeQueryComponent(vatId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By VAT ID and Sender User ID
  // ============================================================
  static Future<List<VatPaymentModel>> findByVatIdAndSenderUserId({
    required String vatId,
    required String senderUserId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/vatIdAndSenderUserId?vatId=${Uri.encodeQueryComponent(vatId)}&senderUserId=${Uri.encodeQueryComponent(senderUserId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Amount >=
  // ============================================================
  static Future<List<VatPaymentModel>> findByAmountGTE(double amount) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/amount/greaterThanEqual?amount=$amount');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Amount <=
  // ============================================================
  static Future<List<VatPaymentModel>> findByAmountLTE(double amount) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/amount/lessThanEqual?amount=$amount');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Transaction ID (containing)
  // ============================================================
  static Future<List<VatPaymentModel>> findByTransactionIdContaining(
      String transactionId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/transactionId/containing?transactionId=${Uri.encodeQueryComponent(transactionId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Transaction ID (exact)
  // ============================================================
  static Future<VatPaymentModel> findByTransactionId(
      String transactionId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/transactionId?transactionId=${Uri.encodeQueryComponent(transactionId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    return VatPaymentModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // SEARCH — Sending Time After (ISO-8601)
  // ============================================================
  static Future<List<VatPaymentModel>> findBySendingTimeAfter(
      DateTime sendingTime) async {
    final iso = sendingTime.toUtc().toIso8601String();
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/sendingTime/after?sendingTime=${Uri.encodeQueryComponent(iso)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — Sending Time Before (ISO-8601)
  // ============================================================
  static Future<List<VatPaymentModel>> findBySendingTimeBefore(
      DateTime sendingTime) async {
    final iso = sendingTime.toUtc().toIso8601String();
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/search/sendingTime/before?sendingTime=${Uri.encodeQueryComponent(iso)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VatPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // DELETE
  // ============================================================
  static Future<bool> deletePayment({
    required String id,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-payment/delete/$id?userId=${Uri.encodeQueryComponent(userId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.delete(uri, headers: headers);

    final json = _handleResponse(response);
    return json['status'] == 'success';
  }

  // ============================================================
  // HELPERS
  // ============================================================
  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
          'Request failed (${response.statusCode}): ${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          json['message'] ?? 'Request failed (${response.statusCode})');
    }

    if (json['status'] == 'error') {
      throw Exception(json['message'] ?? 'Unknown error');
    }

    return json;
  }
}