import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'advocate_documents_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

class AdvocateDocumentsService {
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? '';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static String getAttachmentUrl(String attachmentId) {
    return "${BASE_URL.Urls().baseURL}user/download/$attachmentId";
  }

  // ==================== ADD (Multipart) ====================
  static Future<AdvocateDocuments> addDocuments({
    required String advocateId,
    List<PlatformFile>? files,
  }) async {
    final url = Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate-documents/add/$advocateId");
    final token = await _getToken();

    debugPrint('══════ addDocuments START ══════');
    debugPrint('▶ url                 : $url');
    debugPrint('▶ advocateId          : $advocateId');
    debugPrint('▶ token (len)         : ${token.length}');
    debugPrint('▶ files               : '
        '${files == null ? "null" : files.map((f) => "${f.name} (${f.size}B)").toList()}');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    if (files != null && files.isNotEmpty) {
      for (var file in files) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'files',
            file.path!,
          ));
        }
      }
    }

    debugPrint('▶ request.files.count : ${request.files.length}');
    for (final f in request.files) {
      debugPrint('  – field="${f.field}" filename="${f.filename}" length=${f.length}');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('▶ status              : ${response.statusCode}');
    debugPrint('▶ response body       : ${response.body}');

    if (response.statusCode == 201) {
      debugPrint('✅ addDocuments OK');
      debugPrint('══════ addDocuments END ══════');
      return AdvocateDocuments.fromJson(jsonDecode(response.body));
    } else {
      debugPrint('❌ addDocuments FAILED');
      debugPrint('══════ addDocuments END ══════');
      throw Exception(
          'addDocuments failed [${response.statusCode}]: ${response.body}');
    }
  }

  // ==================== UPDATE (Multipart) ====================
  static Future<AdvocateDocuments> updateDocuments({
    required String id,
    required String userId,
    required AdvocateDocuments documents,
    List<PlatformFile>? newFiles,
  }) async {
    final url = Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate-documents/update/$id/$userId");
    final token = await _getToken();

    debugPrint('══════ updateDocuments START ══════');
    debugPrint('▶ url                 : $url');
    debugPrint('▶ id                  : $id');
    debugPrint('▶ userId              : $userId');
    debugPrint('▶ token (len)         : ${token.length}');
    debugPrint('▶ documents.attachments (${documents.attachments.length}) : ${documents.attachments}');
    debugPrint('▶ newFiles            : '
        '${newFiles == null ? "null" : newFiles.map((f) => "${f.name} (${f.size}B)").toList()}');

    // ═══════════════════════════════════════════════════════════
    // STRATEGY:
    //   1. First attempt: send `documents` + `files` (real files if any,
    //      otherwise an EMPTY files part).
    //   2. If that returns 409 "not uploaded", retry with an empty
    //      files part that has a tiny dummy payload.
    // ═══════════════════════════════════════════════════════════

    Future<http.Response> _doRequest({required bool useDummyFile}) async {
      final req = http.MultipartRequest('PUT', url);
      req.headers['Authorization'] = 'Bearer $token';

      // JSON part
      req.files.add(http.MultipartFile.fromString(
        'documents',
        jsonEncode(documents.toJson()),
        filename: 'documents.json',
        contentType: MediaType('application', 'json'),
      ));

      // Files part — always present
      if (newFiles != null && newFiles.isNotEmpty) {
        for (final file in newFiles) {
          if (kIsWeb) {
            req.files.add(http.MultipartFile.fromBytes(
              'files',
              file.bytes!,
              filename: file.name,
            ));
          } else {
            req.files.add(await http.MultipartFile.fromPath(
              'files',
              file.path!,
            ));
          }
        }
      } else if (useDummyFile) {
        // Non-empty but harmless — forces the backend's files branch.
        req.files.add(http.MultipartFile.fromBytes(
          'files',
          utf8.encode(''),
          filename: '_noop.txt',
          contentType: MediaType('text', 'plain'),
        ));
      }

      debugPrint('── attempt (useDummyFile=$useDummyFile) ──');
      debugPrint('▶ request.files.count : ${req.files.length}');
      for (final f in req.files) {
        debugPrint('  – field="${f.field}" filename="${f.filename}" '
            'contentType=${f.contentType} length=${f.length}');
      }

      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    }

    try {
      // ── Attempt 1: standard ─────────────────────────────────
      var response = await _doRequest(useDummyFile: false);
      debugPrint('▶ attempt 1 status    : ${response.statusCode}');
      debugPrint('▶ attempt 1 body      : ${response.body}');

      // ── Attempt 2 (only if 409): with dummy file ───────────
      if (response.statusCode == 409 &&
          response.body.contains("not uploaded")) {
        debugPrint('↻ Retrying with dummy files part...');
        response = await _doRequest(useDummyFile: true);
        debugPrint('▶ attempt 2 status    : ${response.statusCode}');
        debugPrint('▶ attempt 2 body      : ${response.body}');
      }

      if (response.statusCode == 200) {
        debugPrint('✅ updateDocuments OK');
        debugPrint('══════ updateDocuments END ══════');
        return AdvocateDocuments.fromJson(jsonDecode(response.body));
      }

      debugPrint('❌ updateDocuments FAILED [${response.statusCode}]');
      debugPrint('══════ updateDocuments END ══════');
      throw Exception(
          'updateDocuments failed [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('❌ updateDocuments EXCEPTION: $e');
      debugPrint('══════ updateDocuments END ══════');
      rethrow;
    }
  }

  // ==================== FIND BY ID ====================
  static Future<AdvocateDocuments> findById(String id) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-documents/$id");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return AdvocateDocuments.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  static Future<List<AdvocateDocuments>> findAll() async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate-documents/all");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateDocuments.fromJson(json)).toList();
    } else {
      throw Exception(response.body);
    }
  }

  static Future<AdvocateDocuments> findByAdvocateId(String advocateId) async {
    final url = Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate-documents/advocate/$advocateId");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return AdvocateDocuments.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  static Future<List<AdvocateDocuments>> findByAttachments(
      String attachmentString) async {
    final url = Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate-documents/attachment/$attachmentString");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateDocuments.fromJson(json)).toList();
    } else {
      throw Exception(response.body);
    }
  }

  static Future<bool> deleteDocuments(String id, String userId) async {
    final url = Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate-documents/delete/$id/$userId");
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(response.body);
    }
  }
}