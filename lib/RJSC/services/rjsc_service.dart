// lib/RJSC/services/rjsc_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/rjsc_response_dto.dart';
import '../models/rjsc_registration_process_model.dart';
import '../models/upload_file_model.dart';

class RjscService {
  static String _baseUrl = '${BASE_URL.Urls().baseURL}rjsc';

  // ==========================================================================
  // HELPER: Auth Headers
  // ==========================================================================
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // ==========================================================================
  // HELPER: Resolve mime type (model mimeType first, extension fallback)
  // ==========================================================================
  static MediaType _resolveMimeType(UploadFileModel doc) {
    // ✅ Priority 1: use mimeType from model (web-safe, no path access)
    if (doc.mimeType.isNotEmpty) {
      final parts = doc.mimeType.split('/');
      if (parts.length == 2) {
        return MediaType(parts[0], parts[1]);
      }
    }
    // ✅ Priority 2: derive from extension
    return _getMimeType(doc.extension);
  }

  // ==========================================================================
  // HELPER: Attach documents to MultipartRequest
  // ✅ Multi-device compatible: bytes (Web) + path (Mobile)
  // ✅ MimeType from UploadFileModel (web-safe)
  // ==========================================================================
  static Future<void> _attachDocuments(
    http.MultipartRequest request,
    List<UploadFileModel>? documents,
  ) async {
    if (documents == null || documents.isEmpty) {
      debugPrint('⚠️ No documents to attach');
      return;
    }

    for (final doc in documents) {
      try {
        // ✅ Resolve mime type safely (no path access)
        final mimeType = _resolveMimeType(doc);
        http.MultipartFile? multipartFile;

        // ✅ Priority 1: bytes available (Web + all devices when withData:true)
        if (doc.bytes != null && doc.bytes!.isNotEmpty) {
          multipartFile = http.MultipartFile.fromBytes(
            'documents',
            doc.bytes!,
            filename: doc.fileName,
            contentType: mimeType,
          );
          debugPrint(
              '📎 [Bytes] ${doc.fileName} | ${doc.bytes!.length} bytes | ${doc.mimeType}');
        }
        // ✅ Priority 2: path available (Mobile/Desktop fallback)
        else if (doc.path != null && doc.path!.isNotEmpty) {
          multipartFile = await http.MultipartFile.fromPath(
            'documents',
            doc.path!,
            filename: doc.fileName,
            contentType: mimeType,
          );
          debugPrint('📎 [Path] ${doc.fileName} | ${doc.mimeType}');
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

  // ==========================================================================
  // 1. CREATE — POST /api/rjsc/add  (Multipart)
  // ==========================================================================
  static Future<Map<String, dynamic>> addRjsc({
    required String userId,
    required String compilenceService,
    required String registrationNo,
    required String email,
    required String companyName,
    String? year,
    List<String>? attachmentsId,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/add');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Required fields
      request.fields['userId'] = userId;
      request.fields['compilenceService'] = compilenceService;
      request.fields['registrationNo'] = registrationNo;
      request.fields['email'] = email;
      request.fields['companyName'] = companyName;

      // Optional fields
      if (year != null) request.fields['year'] = year;
      if (attachmentsId != null && attachmentsId.isNotEmpty) {
        request.fields['attachmentsId'] = jsonEncode(attachmentsId);
      }

      // Attach files
      await _attachDocuments(request, documents);

      debugPrint(
          '📤 [addRjsc] Sending ${request.files.length} files, ${request.fields.length} fields');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [addRjsc] Status: ${response.statusCode}');
      debugPrint('📥 [addRjsc] Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ addRjsc error: $e');
      return {
        'status': 'error',
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ==========================================================================
  // 2. UPDATE — PUT /api/rjsc/update/{id}  (Multipart)
  // ==========================================================================
  static Future<Map<String, dynamic>> updateRjsc({
    required String id,
    required String userId,
    String? compilenceService,
    String? registrationNo,
    String? email,
    String? companyName,
    String? year,
    List<String>? attachmentsId,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/update/$id');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('PUT', uri);
      request.headers.addAll(headers);

      // Required
      request.fields['userId'] = userId;

      // Optional
      if (compilenceService != null) {
        request.fields['compilenceService'] = compilenceService;
      }
      if (registrationNo != null) {
        request.fields['registrationNo'] = registrationNo;
      }
      if (email != null) request.fields['email'] = email;
      if (companyName != null) request.fields['companyName'] = companyName;
      if (year != null) request.fields['year'] = year;
      if (attachmentsId != null) {
        request.fields['attachmentsId'] = jsonEncode(attachmentsId);
      }

      // Attach files
      await _attachDocuments(request, documents);

      debugPrint(
          '📤 [updateRjsc] Sending ${request.files.length} files, ${request.fields.length} fields');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [updateRjsc] Status: ${response.statusCode}');
      debugPrint('📥 [updateRjsc] Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ updateRjsc error: $e');
      return {
        'status': 'error',
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ==========================================================================
  // 3. FIND BY ID — GET /api/rjsc/{id}
  // ==========================================================================
static Future<Map<String, dynamic>> findById(String id) async {
  final uri = Uri.parse('${BASE_URL.Urls().baseURL}rjsc/$id');
  final token = await AuthService.getToken();
  final res = await http.get(uri, headers: {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  });
  return _handleResponse(res);
}

static RjscResponseDTO? parseSingle(Map<String, dynamic> json) {
  if (json['status'] == 'success' && json['data'] != null) {
    return RjscResponseDTO.fromJson(
        Map<String, dynamic>.from(json['data']));
  }
  return null;
}

  // ==========================================================================
  // 4. FIND ALL — GET /api/rjsc/all
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
  // 6. FIND BY COMPLIANCE SERVICE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByCompilenceService(
      String compilenceService) async {
    return _getRequest(
        '$_baseUrl/search/compilenceService?compilenceService=${Uri.encodeComponent(compilenceService)}');
  }

  // ==========================================================================
  // 7. FIND BY REGISTRATION NO
  // ==========================================================================
  static Future<Map<String, dynamic>> findByRegistrationNo(
      String registrationNo) async {
    return _getRequest(
        '$_baseUrl/search/registrationNo?registrationNo=${Uri.encodeComponent(registrationNo)}');
  }

  // ==========================================================================
  // 8. FIND BY EMAIL
  // ==========================================================================
  static Future<Map<String, dynamic>> findByEmail(String email) async {
    return _getRequest(
        '$_baseUrl/search/email?email=${Uri.encodeComponent(email)}');
  }

  // ==========================================================================
  // 9. FIND BY COMPANY NAME
  // ==========================================================================
  static Future<Map<String, dynamic>> findByCompanyName(
      String companyName) async {
    return _getRequest(
        '$_baseUrl/search/companyName?companyName=${Uri.encodeComponent(companyName)}');
  }

  // ==========================================================================
  // 10. FIND BY YEAR AFTER
  // ==========================================================================
  static Future<Map<String, dynamic>> findByYearAfter(String yearIso) async {
    return _getRequest(
        '$_baseUrl/search/year/after?year=${Uri.encodeComponent(yearIso)}');
  }

  // ==========================================================================
  // 11. FIND BY YEAR BEFORE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByYearBefore(String yearIso) async {
    return _getRequest(
        '$_baseUrl/search/year/before?year=${Uri.encodeComponent(yearIso)}');
  }

  // ==========================================================================
  // 12. FIND BY DOCUMENTS
  // ==========================================================================
  static Future<Map<String, dynamic>> findByDocuments(
      String documents) async {
    return _getRequest(
        '$_baseUrl/search/documents?documents=${Uri.encodeComponent(documents)}');
  }

  // ==========================================================================
  // 13. DELETE
  // ==========================================================================
  static Future<Map<String, dynamic>> deleteRjsc({
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
      return {
        'status': 'error',
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ==========================================================================
  // 14. VIEW ATTACHMENT URL — GET /api/rjsc/attachment/view/{attachmentId}
  // ==========================================================================
  /// এই URL টি সরাসরি Image.network / WebView / http.get এ ব্যবহার করা যাবে।
  static String viewAttachmentUrl(String attachmentId) {
    return '$_baseUrl/attachment/view/$attachmentId';
  }

  // ==========================================================================
  // 15. DOWNLOAD POST CONTENT URL
  // ==========================================================================
  static String downloadPostContentUrl(String attachmentId) {
    return '$_baseUrl/download/postContent?attachmentId=${Uri.encodeComponent(attachmentId)}';
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
      return {
        'status': 'error',
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return body;
      }
      return {
        'status': 'error',
        'message': 'Unexpected response format',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to parse response: ${response.body}',
      };
    }
  }

  // ==========================================================================
  // MIME TYPE FALLBACK (from extension)
  // ==========================================================================
  static MediaType _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'txt':
        return MediaType('text', 'plain');
      case 'csv':
        return MediaType('text', 'csv');
      case 'xls':
        return MediaType('application', 'vnd.ms-excel');
      case 'xlsx':
        return MediaType('application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  // ==========================================================================
  // TYPED PARSERS
  // ==========================================================================
  static RjscResponseDTO? parseSingleRjsc(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return RjscResponseDTO.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<RjscResponseDTO> parseRjscList(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => RjscResponseDTO.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}