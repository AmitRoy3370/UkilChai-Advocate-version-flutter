// lib/Trademark/services/trademark_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/trademark_response_dto.dart';
import '../models/upload_file_model.dart';

class TrademarkService {
  static String _baseUrl = '${BASE_URL.Urls().baseURL}trademark';

  // ============ HELPERS ============
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

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
        http.MultipartFile multipartFile;

        if (kIsWeb) {
          if (doc.bytes == null || doc.bytes!.isEmpty) {
            debugPrint('❌ Web: bytes empty for ${doc.fileName}');
            continue;
          }
          multipartFile = http.MultipartFile.fromBytes(
            fieldName,
            doc.bytes!,
            filename: doc.fileName,
            contentType: mimeType,
          );
        } else {
          if (doc.path == null || doc.path!.isEmpty) {
            debugPrint('❌ Mobile: path empty for ${doc.fileName}');
            continue;
          }
          multipartFile = await http.MultipartFile.fromPath(
            fieldName,
            doc.path!,
            filename: doc.fileName,
            contentType: mimeType,
          );
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
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  // ==========================================================================
  // 1. CREATE — POST /api/trademark/add  (Multipart)
  // ==========================================================================
  static Future<Map<String, dynamic>> addTrademark({
    required String userId,
    required String legalProtection,
    required String nationWiseValidity,
    required String applicationType,
    required String applicationName,
    required double governmentFee,
    required String organaizationalName,
    required String trademarkName,
    required String trademarkType,
    required String classOfGoods,
    required String adress,
    required String email,
    required String mobileNumber,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/add');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      request.fields['userId'] = userId;
      request.fields['legalProtection'] = legalProtection;
      request.fields['nationWiseValidity'] = nationWiseValidity;
      request.fields['applicationType'] = applicationType;
      request.fields['applicationName'] = applicationName;
      request.fields['governmentFee'] = governmentFee.toString();
      request.fields['organaizationalName'] = organaizationalName;
      request.fields['trademarkName'] = trademarkName;
      request.fields['trademarkType'] = trademarkType;
      request.fields['classOfGoods'] = classOfGoods;
      request.fields['adress'] = adress;
      request.fields['email'] = email;
      request.fields['mobileNumber'] = mobileNumber;

      await _attachDocuments(request, documents, 'documents');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [addTrademark] Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ addTrademark error: $e');
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 2. UPDATE — PUT /api/trademark/update/{id}  (Multipart)
  // ==========================================================================
  static Future<Map<String, dynamic>> updateTrademark({
    required String id,
    required String userId,
    String? legalProtection,
    String? nationWiseValidity,
    String? applicationType,
    String? applicationName,
    double? governmentFee,
    String? organaizationalName,
    String? trademarkName,
    String? trademarkType,
    String? classOfGoods,
    String? adress,
    String? email,
    String? mobileNumber,
    List<String>? documentsId,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/update/$id');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('PUT', uri);
      request.headers.addAll(headers);

      request.fields['userId'] = userId;
      if (legalProtection != null) {
        request.fields['legalProtection'] = legalProtection;
      }
      if (nationWiseValidity != null) {
        request.fields['nationWiseValidity'] = nationWiseValidity;
      }
      if (applicationType != null) {
        request.fields['applicationType'] = applicationType;
      }
      if (applicationName != null) {
        request.fields['applicationName'] = applicationName;
      }
      if (governmentFee != null) {
        request.fields['governmentFee'] = governmentFee.toString();
      }
      if (organaizationalName != null) {
        request.fields['organaizationalName'] = organaizationalName;
      }
      if (trademarkName != null) {
        request.fields['trademarkName'] = trademarkName;
      }
      if (trademarkType != null) {
        request.fields['trademarkType'] = trademarkType;
      }
      if (classOfGoods != null) {
        request.fields['classOfGoods'] = classOfGoods;
      }
      if (adress != null) request.fields['adress'] = adress;
      if (email != null) request.fields['email'] = email;
      if (mobileNumber != null) {
        request.fields['mobileNumber'] = mobileNumber;
      }
      if (documentsId != null) {
        request.fields['documentsId'] = jsonEncode(documentsId);
      }

      await _attachDocuments(request, documents, 'documents');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [updateTrademark] Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ updateTrademark error: $e');
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 3. FIND BY ID — GET /api/trademark/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }

  // ==========================================================================
  // 4. FIND ALL — GET /api/trademark/all
  // ==========================================================================
  static Future<Map<String, dynamic>> findAll() async {
    return _getRequest('$_baseUrl/all');
  }

  // ==========================================================================
  // 5. FIND BY LEGAL PROTECTION
  // ==========================================================================
  static Future<Map<String, dynamic>> findByLegalProtection(String value) async {
    return _getRequest(
        '$_baseUrl/search/legalProtection?legalProtection=${Uri.encodeComponent(value)}');
  }

  // ==========================================================================
  // 6. FIND BY NATION WISE VALIDITY
  // ==========================================================================
  static Future<Map<String, dynamic>> findByNationWiseValidity(
      String value) async {
    return _getRequest(
        '$_baseUrl/search/nationWiseValidity?nationWiseValidity=${Uri.encodeComponent(value)}');
  }

  // ==========================================================================
  // 7. FIND BY APPLICATION TYPE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByApplicationType(
      String value) async {
    return _getRequest(
        '$_baseUrl/search/applicationType?applicationType=${Uri.encodeComponent(value)}');
  }

  // ==========================================================================
  // 8. FIND BY APPLICATION NAME
  // ==========================================================================
  static Future<Map<String, dynamic>> findByApplicationName(
      String value) async {
    return _getRequest(
        '$_baseUrl/search/applicationName?applicationName=${Uri.encodeComponent(value)}');
  }

  // ==========================================================================
  // 9. FIND BY GOVERNMENT FEE >=
  // ==========================================================================
  static Future<Map<String, dynamic>> findByGovernmentFeeGte(
      double fee) async {
    return _getRequest(
        '$_baseUrl/search/governmentFee/greaterThan?governmentFee=$fee');
  }

  // ==========================================================================
  // 10. FIND BY GOVERNMENT FEE <=
  // ==========================================================================
  static Future<Map<String, dynamic>> findByGovernmentFeeLte(
      double fee) async {
    return _getRequest(
        '$_baseUrl/search/governmentFee/lessThan?governmentFee=$fee');
  }

  // ==========================================================================
  // 11. FIND BY EMAIL (exact)
  // ==========================================================================
  static Future<Map<String, dynamic>> findByEmail(String email) async {
    return _getRequest(
        '$_baseUrl/search/email?email=${Uri.encodeComponent(email)}');
  }

  // ==========================================================================
  // 12. FIND BY EMAIL (containing)
  // ==========================================================================
  static Future<Map<String, dynamic>> findByEmailContaining(
      String email) async {
    return _getRequest(
        '$_baseUrl/search/email/containing?email=${Uri.encodeComponent(email)}');
  }

  // ==========================================================================
  // 13. FIND BY MOBILE NUMBER (exact)
  // ==========================================================================
  static Future<Map<String, dynamic>> findByMobileNumber(
      String mobile) async {
    return _getRequest(
        '$_baseUrl/search/mobileNumber?mobileNumber=${Uri.encodeComponent(mobile)}');
  }

  // ==========================================================================
  // 14. FIND BY MOBILE NUMBER (containing)
  // ==========================================================================
  static Future<Map<String, dynamic>> findByMobileNumberContaining(
      String mobile) async {
    return _getRequest(
        '$_baseUrl/search/mobileNumber/containing?mobileNumber=${Uri.encodeComponent(mobile)}');
  }

  // ==========================================================================
  // 15. FIND BY DOCUMENTS
  // ==========================================================================
  static Future<Map<String, dynamic>> findByDocuments(String document) async {
    return _getRequest(
        '$_baseUrl/search/documents?documents=${Uri.encodeComponent(document)}');
  }

  // ==========================================================================
  // 16. FIND BY USER ID
  // ==========================================================================
  static Future<Map<String, dynamic>> findByUserId(String userId) async {
    return _getRequest(
        '$_baseUrl/search/userId?userId=${Uri.encodeComponent(userId)}');
  }

  // ==========================================================================
  // 17. FIND BY ADDRESS
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAdress(String value) async {
    return _getRequest(
        '$_baseUrl/search/adress?adress=${Uri.encodeComponent(value)}');
  }

  // ==========================================================================
  // 18. FIND BY TRADEMARK NAME
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTrademarkName(
      String value) async {
    return _getRequest(
        '$_baseUrl/search/trademarkName?trademarkName=${Uri.encodeComponent(value)}');
  }

  // ==========================================================================
  // 19. FIND BY TRADEMARK TYPE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTrademarkType(
      String value) async {
    return _getRequest(
        '$_baseUrl/search/trademarkType?trademarkType=${Uri.encodeComponent(value)}');
  }

  // ==========================================================================
  // 20. FIND BY CLASS OF GOODS
  // ==========================================================================
  static Future<Map<String, dynamic>> findByClassOfGoods(
      String value) async {
    return _getRequest(
        '$_baseUrl/search/classOfGoods?classOfGoods=${Uri.encodeComponent(value)}');
  }

  // ==========================================================================
  // 21. DELETE — DELETE /api/trademark/delete/{id}?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> deleteTrademark({
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
  static TrademarkResponse? parseSingle(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return TrademarkResponse.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<TrademarkResponse> parseList(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => TrademarkResponse.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}