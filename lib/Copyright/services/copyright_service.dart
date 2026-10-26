// lib/Copyright/services/copyright_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../Auth/AuthService.dart';
import '../../Utils/BaseURL.dart' as BASE_URL;

import '../models/copyright_response_dto.dart';
import '../models/upload_file_model.dart';

class CopyrightService {
  static String _baseUrl = '${BASE_URL.Urls().baseURL}copyright';

  // ============ HELPERS ============
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  /// ✅ Multi-device compatible file attach
  /// - Priority 1: `bytes` (Web + whenever available)
  /// - Priority 2: `path` (Mobile/Desktop fallback)
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
        final mimeType = _getMimeType(doc.extension);
        http.MultipartFile? multipartFile;

        // ✅ Priority 1: bytes available (Web + case-page style withData:true)
        if (doc.bytes != null && doc.bytes!.isNotEmpty) {
          multipartFile = http.MultipartFile.fromBytes(
            'documents',
            doc.bytes!,
            filename: doc.fileName,
            contentType: mimeType,
          );
          debugPrint(
              '📎 [Bytes] ${doc.fileName} (${doc.bytes!.length} bytes)');
        }
        // ✅ Priority 2: path available (Mobile/Desktop fallback)
        else if (doc.path != null && doc.path!.isNotEmpty) {
          multipartFile = await http.MultipartFile.fromPath(
            'documents',
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
  // 1. CREATE — POST /api/copyright/add  (Multipart)
  // ==========================================================================
  static Future<Map<String, dynamic>> addCopyright({
    required String userId,
    required String author,
    required String typeOfWork,
    required String yearOfCreation, // ISO-8601
    required String titleOfWork,
    required String description,
    required String applicationName,
    required String mobileNumber,
    required String email,
    required String adress,
    List<String>? documentsId,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/add');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      request.fields['userId'] = userId;
      request.fields['author'] = author;
      request.fields['typeOfWork'] = typeOfWork;
      request.fields['yearOfCreation'] = yearOfCreation;
      request.fields['titleOfWork'] = titleOfWork;
      request.fields['description'] = description;
      request.fields['applicationName'] = applicationName;
      request.fields['mobileNumber'] = mobileNumber;
      request.fields['email'] = email;
      request.fields['adress'] = adress;

      if (documentsId != null && documentsId.isNotEmpty) {
        request.fields['documentsId'] = jsonEncode(documentsId);
      }

      await _attachDocuments(request, documents);

      debugPrint(
          '📤 [addCopyright] files=${request.files.length} fields=${request.fields.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [addCopyright] Status: ${response.statusCode}');
      debugPrint('📥 [addCopyright] Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ addCopyright error: $e');
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 2. UPDATE — PUT /api/copyright/update/{id}  (Multipart)
  // ==========================================================================
  static Future<Map<String, dynamic>> updateCopyright({
    required String id,
    required String userId,
    String? author,
    String? typeOfWork,
    String? yearOfCreation,
    String? titleOfWork,
    String? description,
    String? applicationName,
    String? mobileNumber,
    String? email,
    String? adress,
    List<String>? documentsId,
    List<UploadFileModel>? documents,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/update/$id');
      final headers = await _authHeaders();

      final request = http.MultipartRequest('PUT', uri);
      request.headers.addAll(headers);

      request.fields['userId'] = userId;
      if (author != null) request.fields['author'] = author;
      if (typeOfWork != null) request.fields['typeOfWork'] = typeOfWork;
      if (yearOfCreation != null) {
        request.fields['yearOfCreation'] = yearOfCreation;
      }
      if (titleOfWork != null) request.fields['titleOfWork'] = titleOfWork;
      if (description != null) request.fields['description'] = description;
      if (applicationName != null) {
        request.fields['applicationName'] = applicationName;
      }
      if (mobileNumber != null) request.fields['mobileNumber'] = mobileNumber;
      if (email != null) request.fields['email'] = email;
      if (adress != null) request.fields['adress'] = adress;
      if (documentsId != null) {
        request.fields['documentsId'] = jsonEncode(documentsId);
      }

      await _attachDocuments(request, documents);

      debugPrint(
          '📤 [updateCopyright] files=${request.files.length} fields=${request.fields.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [updateCopyright] Status: ${response.statusCode}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ updateCopyright error: $e');
      return {'status': 'error', 'message': 'Network error: ${e.toString()}'};
    }
  }

  // ==========================================================================
  // 3. FIND BY ID — GET /api/copyright/{id}
  // ==========================================================================
  static Future<Map<String, dynamic>> findById(String id) async {
    return _getRequest('$_baseUrl/$id');
  }

  // ==========================================================================
  // 4. FIND ALL — GET /api/copyright/all
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
  // 6. FIND BY AUTHOR
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAuthor(String author) async {
    return _getRequest(
        '$_baseUrl/search/author?author=${Uri.encodeComponent(author)}');
  }

  // ==========================================================================
  // 7. FIND BY TYPE OF WORK
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTypeOfWork(String typeOfWork) async {
    return _getRequest(
        '$_baseUrl/search/typeOfWork?typeOfWork=${Uri.encodeComponent(typeOfWork)}');
  }

  // ==========================================================================
  // 8. FIND BY YEAR AFTER
  // ==========================================================================
  static Future<Map<String, dynamic>> findByYearOfCreationAfter(
      String yearIso) async {
    return _getRequest(
        '$_baseUrl/search/yearOfCreation/after?yearOfCreation=${Uri.encodeComponent(yearIso)}');
  }

  // ==========================================================================
  // 9. FIND BY YEAR BEFORE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByYearOfCreationBefore(
      String yearIso) async {
    return _getRequest(
        '$_baseUrl/search/yearOfCreation/before?yearOfCreation=${Uri.encodeComponent(yearIso)}');
  }

  // ==========================================================================
  // 10. FIND BY TITLE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByTitleOfWork(
      String titleOfWork) async {
    return _getRequest(
        '$_baseUrl/search/titleOfWork?titleOfWork=${Uri.encodeComponent(titleOfWork)}');
  }

  // ==========================================================================
  // 11. FIND BY DESCRIPTION
  // ==========================================================================
  static Future<Map<String, dynamic>> findByDescription(
      String description) async {
    return _getRequest(
        '$_baseUrl/search/description?description=${Uri.encodeComponent(description)}');
  }

  // ==========================================================================
  // 12. FIND BY APPLICATION NAME
  // ==========================================================================
  static Future<Map<String, dynamic>> findByApplicationName(
      String applicationName) async {
    return _getRequest(
        '$_baseUrl/search/applicationName?applicationName=${Uri.encodeComponent(applicationName)}');
  }

  // ==========================================================================
  // 13. FIND BY MOBILE
  // ==========================================================================
  static Future<Map<String, dynamic>> findByMobileNumber(
      String mobileNumber) async {
    return _getRequest(
        '$_baseUrl/search/mobileNumber?mobileNumber=${Uri.encodeComponent(mobileNumber)}');
  }

  // ==========================================================================
  // 14. FIND BY EMAIL
  // ==========================================================================
  static Future<Map<String, dynamic>> findByEmail(String email) async {
    return _getRequest(
        '$_baseUrl/search/email?email=${Uri.encodeComponent(email)}');
  }

  // ==========================================================================
  // 15. FIND BY ADDRESS
  // ==========================================================================
  static Future<Map<String, dynamic>> findByAdress(String adress) async {
    return _getRequest(
        '$_baseUrl/search/adress?adress=${Uri.encodeComponent(adress)}');
  }

  // ==========================================================================
  // 16. FIND BY DOCUMENTS
  // ==========================================================================
  static Future<Map<String, dynamic>> findByDocuments(String documents) async {
    return _getRequest(
        '$_baseUrl/search/documents?documents=${Uri.encodeComponent(documents)}');
  }

  // ==========================================================================
  // 17. DELETE
  // ==========================================================================
  static Future<Map<String, dynamic>> deleteCopyright({
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
  // 18. VIEW / DOWNLOAD ATTACHMENT URL (Multi-device)
  // ==========================================================================
  /// ✅ যেকোনো device থেকে এই URL দিয়ে file দেখা যাবে
  /// ব্যবহার: `Image.network(CopyrightService.getAttachmentViewUrl(id))`
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
  static CopyrightResponseDTO? parseSingle(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return CopyrightResponseDTO.fromJson(
          Map<String, dynamic>.from(json['data']));
    }
    return null;
  }

  static List<CopyrightResponseDTO> parseList(Map<String, dynamic> json) {
    if (json['status'] == 'success' && json['data'] != null) {
      return (json['data'] as List)
          .map(
              (e) => CopyrightResponseDTO.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}