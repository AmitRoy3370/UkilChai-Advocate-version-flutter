// lib/vat/service/vat_registration_process_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/vat_registration_process_model.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;
import 'vat_auth_helper.dart';   // ✅ NEW

class VatRegistrationProcessService {
  static String get _baseUrl => BASE_URL.Urls().baseURL;

  // ============================================================
  // CREATE
  // ============================================================
  static Future<VatRegistrationProcessModel> addProcess({
    required VatRegistrationProcessModel process,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/add?userId=${Uri.encodeQueryComponent(userId)}');

    final headers = await VatAuthHelper.jsonHeaders();   // ✅ JWT + JSON
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(process.toJson()),
    );

    final json = _handleResponse(response);
    return VatRegistrationProcessModel.fromJson(
        json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // UPDATE
  // ============================================================
  static Future<VatRegistrationProcessModel> updateProcess({
    required String id,
    required VatRegistrationProcessModel process,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/update/$id?userId=${Uri.encodeQueryComponent(userId)}');

    final headers = await VatAuthHelper.jsonHeaders();   // ✅ JWT + JSON
    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(process.toJson()),
    );

    final json = _handleResponse(response);
    return VatRegistrationProcessModel.fromJson(
        json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // READ — By ID
  // ============================================================
  static Future<VatRegistrationProcessModel> findById(String id) async {
    final uri = Uri.parse('${_baseUrl}vat-registration/$id');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    return VatRegistrationProcessModel.fromJson(
        json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // READ — All
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findAll() async {
    final uri = Uri.parse('${_baseUrl}vat-registration/all');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By VAT ID (single)
  // ============================================================
  static Future<VatRegistrationProcessModel> findByVatId(String vatId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/search/vatId?vatId=${Uri.encodeQueryComponent(vatId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    return VatRegistrationProcessModel.fromJson(
        json['data'] as Map<String, dynamic>);
  }

  // ============================================================
  // SEARCH — By VAT ID IN (list)
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findByVatIdIn(
      List<String> vatsId) async {
    final query = vatsId
        .map((id) => 'vatsId=${Uri.encodeQueryComponent(id)}')
        .join('&');
    final uri = Uri.parse('${_baseUrl}vat-registration/search/vatIdIn?$query');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By User ID
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findByUserId(
      String userId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/search/userId?userId=${Uri.encodeQueryComponent(userId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Advocate ID
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findByAdvocateId(
      String advocateId) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/search/advocateId?advocateId=${Uri.encodeQueryComponent(advocateId)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Status
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findByStatus(
      bool status) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/search/status?status=$status');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEARCH — By Steps (containing, ignore case)
  // ============================================================
  static Future<List<VatRegistrationProcessModel>> findBySteps(
      String steps) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/search/steps?steps=${Uri.encodeQueryComponent(steps)}');
    final headers = await VatAuthHelper.getHeaders();
    final response = await http.get(uri, headers: headers);

    final json = _handleResponse(response);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            VatRegistrationProcessModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // DELETE
  // ============================================================
  static Future<bool> deleteProcess({
    required String id,
    required String userId,
  }) async {
    final uri = Uri.parse(
        '${_baseUrl}vat-registration/delete/$id?userId=${Uri.encodeQueryComponent(userId)}');
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