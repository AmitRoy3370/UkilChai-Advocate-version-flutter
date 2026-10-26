// lib/TradeLicense/services/trade_license_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/trade_license_response_dto.dart';
import '../models/upload_file_model.dart';

class TradeLicenseService {
  static String _baseUrl = '${BASE_URL.Urls().baseURL}trade-license';

  // ============ HELPERS ============
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  /// ✅ Multi-device compatible file attach
  /// - Priority 1: `bytes` (Web + wherever available)
  /// - Priority 2: `path` (Mobile/Desktop fallback)
  static Future<void> _attachDocuments(
    http.MultipartRequest request,
    List<UploadFileModel>? documents,
    String fieldName,
  ) async {
    if (documents == null || documents.isEmpty) {
      debugPrint('⚠️ No documents to attach');
      return;
    }

    for (final doc in documents) {
      try {
        final mimeType = _getMimeType(doc.extension);
        http.MultipartFile? multipartFile;

        // ✅ Priority 1: bytes (works for web + case-page style withData:true)
        if (doc.bytes != null && doc.bytes!.isNotEmpty) {
          multipartFile = http.MultipartFile.fromBytes(
            fieldName,
            doc.bytes!,
            filename: doc.fileName,
            contentType: mimeType,
          );
          debugPrint(
              '📎 [Bytes] ${doc.fileName} (${doc.bytes!.length} bytes)');
        }
        // ✅ Priority 2: path (mobile/desktop fallback)
        else if (doc.path != null && doc.path!.isNotEmpty) {
          multipartFile = await http.MultipartFile.fromPath(
            fieldName,
            doc.path!,
            filename: doc.fileName,
            contentType: mimeType,
          );
          debugPrint('📎 [Path] ${doc.fileName} → ${doc.path}');
        }
        // ❌ Neither → skip
        else {
          debugPrint('❌ Skipped ${doc.fileName}: no bytes or path');
          continue;
        }

        request.files.add(multipartFile);
      } catch (e) {
        debugPrint('❌ Error attaching ${doc.fileName}: $e');
      }
    }
  }

  static MediaType _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'txt':
        return MediaType('text', 'plain');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  // ==========================================================================
  // 1. CREATE WITH FILES — POST /api/trade-license/add
  // ==========================================================================
  static Future<Map<String, dynamic>> addTradeLicense({
    required String userId,
    required String buisnessName,
    required String mobileNumber,
    required String emailAdress,
    required String buisnessType,
    required String buisnessCategory,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/add');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      request.fields['userId'] = userId;
      request.fields['buisnessName'] = buisnessName;
      request.fields['mobileNumber'] = mobileNumber;
      request.fields['emailAdress'] = emailAdress;
      request.fields['buisnessType'] = buisnessType;
      request.fields['buisnessCategory'] = buisnessCategory;

      await _attachDocuments(request, documents, 'documents');

      debugPrint(
          '📤 [addTradeLicense] files=${request.files.length} fields=${request.fields.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [addTradeLicense] Status: ${response.statusCode}');
      debugPrint('📥 [addTradeLicense] Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ addTradeLicense error: $e');
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 2. UPDATE WITH FILES — PUT /api/trade-license/update/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> updateTradeLicense({
    required String id,
    required String userId,
    required String buisnessName,
    required String mobileNumber,
    required String emailAdress,
    required String buisnessType,
    required String buisnessCategory,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/update/$id');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('PUT', uri);
      request.headers.addAll(headers);

      request.fields['userId'] = userId;
      request.fields['buisnessName'] = buisnessName;
      request.fields['mobileNumber'] = mobileNumber;
      request.fields['emailAdress'] = emailAdress;
      request.fields['buisnessType'] = buisnessType;
      request.fields['buisnessCategory'] = buisnessCategory;

      await _attachDocuments(request, documents, 'documents');

      debugPrint(
          '📤 [updateTradeLicense] files=${request.files.length} fields=${request.fields.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [updateTradeLicense] Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ updateTradeLicense error: $e');
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 3. UPDATE PARTIAL — PUT /api/trade-license/update/{id}/partial
  // ==========================================================================
  static Future<Map<String, dynamic>> updateTradeLicensePartial({
    required String id,
    required String userId,
    String? buisnessName,
    String? mobileNumber,
    String? emailAdress,
    String? buisnessType,
    String? buisnessCategory,
    List<String>? attachmentsId,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/update/$id/partial');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('PUT', uri);
      request.headers.addAll(headers);

      request.fields['userId'] = userId;
      if (buisnessName != null) request.fields['buisnessName'] = buisnessName;
      if (mobileNumber != null) request.fields['mobileNumber'] = mobileNumber;
      if (emailAdress != null) request.fields['emailAdress'] = emailAdress;
      if (buisnessType != null) request.fields['buisnessType'] = buisnessType;
      if (buisnessCategory != null) {
        request.fields['buisnessCategory'] = buisnessCategory;
      }
      if (attachmentsId != null) {
        request.fields['attachmentsId'] = jsonEncode(attachmentsId);
      }

      await _attachDocuments(request, documents, 'documents');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 4. FIND BY ID — GET /api/trade-license/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }

  // ==========================================================================
  // 5. FIND ALL — GET /api/trade-license/all
  // ==========================================================================
  static Future<Map<String, dynamic>> findAll() async {
    return _getRequest('$_baseUrl/all');
  }

  // ==========================================================================
  // 6. FIND BY USER ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByUserId(String userId) async {
    return _getRequest(
        '$_baseUrl/search/user?userId=${Uri.encodeComponent(userId)}');
  }

  // ==========================================================================
  // 7. FIND BY BUSINESS NAME
  // ==========================================================================
  static Future<Map<String, dynamic>> findByBusinessName(String name) async {
    return _getRequest(
        '$_baseUrl/search/businessName?buisnessName=${Uri.encodeComponent(name)}');
  }

  // ==========================================================================
  // 8. FIND BY MOBILE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByMobileNumber(String mobile) async {
    return _getRequest(
        '$_baseUrl/search/mobile?mobileNumber=${Uri.encodeComponent(mobile)}');
  }

  // ==========================================================================
  // 9. FIND BY EMAIL
  // ==========================================================================
  static Future<Map<String, dynamic>> findByEmail(String email) async {
    return _getRequest(
        '$_baseUrl/search/email?emailAdress=${Uri.encodeComponent(email)}');
  }

  // ==========================================================================
  // 10. FIND BY BUSINESS TYPE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByBusinessType(String type) async {
    return _getRequest(
        '$_baseUrl/search/businessType?buisnessType=${Uri.encodeComponent(type)}');
  }

  // ==========================================================================
  // 11. FIND BY BUSINESS CATEGORY
  // ==========================================================================
  static Future<Map<String, dynamic>> findByBusinessCategory(
      String category) async {
    return _getRequest(
        '$_baseUrl/search/businessCategory?buisnessCategory=${Uri.encodeComponent(category)}');
  }

  // ==========================================================================
  // 12. FIND BY DOCUMENT
  // ==========================================================================
  static Future<Map<String, dynamic>> findByDocument(String document) async {
    return _getRequest(
        '$_baseUrl/search/document?document=${Uri.encodeComponent(document)}');
  }

  // ==========================================================================
  // 13. DELETE
  // ==========================================================================
  static Future<Map<String, dynamic>> deleteTradeLicense({
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
  // 14. VIEW / DOWNLOAD ATTACHMENT URL
  // ==========================================================================
  /// ✅ Multi-device: যেকোনো device থেকে এই URL দিয়ে file দেখা যাবে
  /// ব্যবহার: `Image.network(TradeLicenseService.getAttachmentViewUrl(id))`
  static String getAttachmentViewUrl(String attachmentId) =>
      '$_baseUrl/attachment/view/$attachmentId';

  static String getAttachmentDownloadUrl(String attachmentId) =>
      '$_baseUrl/attachment/$attachmentId';

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
  static TradeLicenseResponseDTO? parseSingle(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return TradeLicenseResponseDTO.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<TradeLicenseResponseDTO> parseList(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) =>
              TradeLicenseResponseDTO.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}