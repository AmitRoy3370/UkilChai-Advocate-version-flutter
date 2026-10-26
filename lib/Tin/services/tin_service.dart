// lib/Tin/services/tin_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/tin_response_dto.dart';
import '../models/upload_file_model.dart';

class TinService {
  static String _baseUrl = '${BASE_URL.Urls().baseURL}tin';

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
  /// - Priority 2: `path` (Mobile fallback)
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

        // ✅ Priority 1: bytes
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
        // ✅ Priority 2: path
        else if (doc.path != null && doc.path!.isNotEmpty) {
          multipartFile = await http.MultipartFile.fromPath(
            fieldName,
            doc.path!,
            filename: doc.fileName,
            contentType: mimeType,
          );
          debugPrint('📎 [Path] ${doc.fileName}');
        } else {
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
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  // ==========================================================================
  // 1. CREATE — POST /api/tin/add  (Multipart)
  // ==========================================================================
  static Future<Map<String, dynamic>> addTin({
    required String userId,
    required String fullName,
    required String fatherName,
    required String motherName,
    required String phone,
    required String dateOfBirth, // ISO-8601
    required String presentAdress,
    required String permanentAdress,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/add');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      request.fields['userId'] = userId;
      request.fields['fullName'] = fullName;
      request.fields['fatherName'] = fatherName;
      request.fields['motherName'] = motherName;
      request.fields['phone'] = phone;
      request.fields['dateOfBirth'] = dateOfBirth;
      request.fields['presentAdress'] = presentAdress;
      request.fields['permanentAdress'] = permanentAdress;

      await _attachDocuments(request, documents, 'documents');

      debugPrint('📤 [addTin] Sending ${request.files.length} files...');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [addTin] Status: ${response.statusCode}');
      debugPrint('📥 [addTin] Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ addTin error: $e');
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 2. UPDATE — PUT /api/tin/update/{id}  (Multipart)
  // ==========================================================================
  static Future<Map<String, dynamic>> updateTin({
    required String id,
    required String userId,
    String? fullName,
    String? fatherName,
    String? motherName,
    String? phone,
    String? dateOfBirth,
    String? presentAdress,
    String? permanentAdress,
    List<String>? documentsId,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/update/$id');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('PUT', uri);
      request.headers.addAll(headers);

      request.fields['userId'] = userId;
      if (fullName != null) request.fields['fullName'] = fullName;
      if (fatherName != null) request.fields['fatherName'] = fatherName;
      if (motherName != null) request.fields['motherName'] = motherName;
      if (phone != null) request.fields['phone'] = phone;
      if (dateOfBirth != null) request.fields['dateOfBirth'] = dateOfBirth;
      if (presentAdress != null) request.fields['presentAdress'] = presentAdress;
      if (permanentAdress != null) {
        request.fields['permanentAdress'] = permanentAdress;
      }
      if (documentsId != null) {
        request.fields['attachmentsId'] = jsonEncode(documentsId);
      }

      await _attachDocuments(request, documents, 'documents');

      debugPrint('📤 [updateTin] Sending ${request.files.length} files...');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [updateTin] Status: ${response.statusCode}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ updateTin error: $e');
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 3. FIND BY ID — GET /api/tin/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }



  // ==========================================================================
  // 4. FIND ALL — GET /api/tin/all
  // ==========================================================================
  static Future<Map<String, dynamic>> findAll() async {
    return _getRequest('$_baseUrl/all');
  }

  // ==========================================================================
  // 5. FIND BY FULL NAME
  // ==========================================================================
  static Future<Map<String, dynamic>> findByFullName(String fullName) async {
    return _getRequest(
        '$_baseUrl/search/fullName?fullName=${Uri.encodeComponent(fullName)}');
  }

  // ==========================================================================
  // 6. FIND BY FATHER NAME
  // ==========================================================================
  static Future<Map<String, dynamic>> findByFatherName(
      String fatherName) async {
    return _getRequest(
        '$_baseUrl/search/fatherName?fatherName=${Uri.encodeComponent(fatherName)}');
  }

  // ==========================================================================
  // 7. FIND BY MOTHER NAME
  // ==========================================================================
  static Future<Map<String, dynamic>> findByMotherName(
      String motherName) async {
    return _getRequest(
        '$_baseUrl/search/motherName?motherName=${Uri.encodeComponent(motherName)}');
  }

  // ==========================================================================
  // 8. FIND BY PHONE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByPhone(String phone) async {
    return _getRequest(
        '$_baseUrl/search/phone?phone=${Uri.encodeComponent(phone)}');
  }

  // ==========================================================================
  // 9. FIND BY DOB BEFORE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByDateOfBirthBefore(
      String isoDate) async {
    return _getRequest(
        '$_baseUrl/search/birthBefore?dateOfBirth=${Uri.encodeComponent(isoDate)}');
  }

  // ==========================================================================
  // 10. FIND BY DOB AFTER
  // ==========================================================================
  static Future<Map<String, dynamic>> findByDateOfBirthAfter(
      String isoDate) async {
    return _getRequest(
        '$_baseUrl/search/birthAfter?dateOfBirth=${Uri.encodeComponent(isoDate)}');
  }

  // ==========================================================================
  // 11. FIND BY PRESENT ADDRESS
  // ==========================================================================
  static Future<Map<String, dynamic>> findByPresentAddress(
      String address) async {
    return _getRequest(
        '$_baseUrl/search/presentAddress?presentAdress=${Uri.encodeComponent(address)}');
  }

  // ==========================================================================
  // 12. FIND BY PERMANENT ADDRESS
  // ==========================================================================
  static Future<Map<String, dynamic>> findByPermanentAddress(
      String address) async {
    return _getRequest(
        '$_baseUrl/search/permanentAddress?permanentAdress=${Uri.encodeComponent(address)}');
  }

  // ==========================================================================
  // 13. FIND BY DOCUMENT
  // ==========================================================================
  static Future<Map<String, dynamic>> findByDocument(String document) async {
    return _getRequest(
        '$_baseUrl/search/document?document=${Uri.encodeComponent(document)}');
  }

  // ==========================================================================
  // 14. DELETE — DELETE /api/tin/delete/{id}?userId=...
  // ==========================================================================
  static Future<Map<String, dynamic>> deleteTin({
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
  // 15. ATTACHMENT VIEW URL
  // ==========================================================================
  static String getAttachmentViewUrl(String attachmentId) =>
      '$_baseUrl/attachment/view/$attachmentId';

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
  static TinResponseDTO? parseSingle(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return TinResponseDTO.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<TinResponseDTO> parseList(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map((e) => TinResponseDTO.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}