// CaseJudgmentService.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './AuthHeader.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'CaseJudgmentModel.dart';

class CaseJudgmentService {
  static String baseUrl = "${BASE_URL.Urls().baseURL}case-judgment";

  // ================= MIME TYPE =================
  static String? getMimeType(String? extension) {
    if (extension == null) return null;
    extension = extension.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  // ================= ADD =================
  static Future<CaseJudgment> addJudgment({
    required String caseId,
    required String result,
    required String userId,
    PlatformFile? file,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");

    final uri = Uri.parse("$baseUrl/add?userId=$userId");

    final request = http.MultipartRequest("POST", uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['caseId'] = caseId
      ..fields['result'] = result;

    if (date != null) {
      request.fields['date'] = date.toUtc().toIso8601String();
    }

    await _attachFileAsync(request, file);   // ✅ FIXED: was sync _attachFile

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint("═══ ADD JUDGMENT ═══");
    debugPrint("Status: ${response.statusCode}");
    debugPrint("Body: ${response.body}");
    debugPrint("══════════════════════");

    _ensureOk(response);

    return CaseJudgment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ================= UPDATE =================
  static Future<CaseJudgment> updateJudgment({
    required String judgmentId,
    required String caseId,
    required String result,
    required String userId,
    String? oldAttachmentId,
    PlatformFile? file,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");

    final uri = Uri.parse("$baseUrl/update/$judgmentId?userId=$userId");

    final request = http.MultipartRequest("PUT", uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['caseId'] = caseId
      ..fields['result'] = result;

    if (oldAttachmentId != null && oldAttachmentId.isNotEmpty) {
      request.fields['judgmentAttachmentId'] = oldAttachmentId;
    }

    if (date != null) {
      request.fields['date'] = date.toUtc().toIso8601String();
    }

    await _attachFileAsync(request, file);   // ✅ FIXED

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint("═══ UPDATE JUDGMENT ═══");
    debugPrint("Status: ${response.statusCode}");
    debugPrint("Body: ${response.body}");
    debugPrint("══════════════════════");

    _ensureOk(response);

    return CaseJudgment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ================= FIND BY CASE =================
  static Future<CaseJudgmentResponse?> getByCase(String caseId) async {
    final headers = await AuthHeader.getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/case/$caseId"),
      headers: headers,
    );

    debugPrint("═══ GET JUDGMENT BY CASE ═══");
    debugPrint("URL: $baseUrl/case/$caseId");
    debugPrint("Status: ${response.statusCode}");
    debugPrint("Body: ${response.body}");
    debugPrint("════════════════════════════");

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return CaseJudgmentResponse.fromJson(decoded);
        }
        debugPrint("⚠️ Non-map body, skipping: $decoded");
        return null;
      } catch (e) {
        debugPrint("⚠️ JSON parse error: $e");
        return null;
      }
    }
    if (response.statusCode == 404 || response.statusCode == 204) {
      return null;
    }
    _ensureOk(response);
    return null;
  }

  // ================= FIND BY ID =================
  static Future<CaseJudgmentResponse> getById(String id) async {
    final headers = await AuthHeader.getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: headers,
    );
    _ensureOk(response);
    return CaseJudgmentResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ================= FIND ALL =================
  static Future<List<CaseJudgmentResponse>> getAll() async {
    final headers = await AuthHeader.getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/all"),
      headers: headers,
    );
    _ensureOk(response);
    return (jsonDecode(response.body) as List)
        .map((e) => CaseJudgmentResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= SEARCH BY RESULT =================
  static Future<List<CaseJudgmentResponse>> searchByResult(
      String result) async {
    final headers = await AuthHeader.getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/search?result=${Uri.encodeQueryComponent(result)}"),
      headers: headers,
    );
    _ensureOk(response);
    return (jsonDecode(response.body) as List)
        .map((e) => CaseJudgmentResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= AFTER DATE =================
  static Future<List<CaseJudgmentResponse>> afterDate(DateTime date) async {
    final headers = await AuthHeader.getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/after?date=${date.toUtc().toIso8601String()}"),
      headers: headers,
    );
    _ensureOk(response);
    return (jsonDecode(response.body) as List)
        .map((e) => CaseJudgmentResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= BEFORE DATE =================
  static Future<List<CaseJudgmentResponse>> beforeDate(DateTime date) async {
    final headers = await AuthHeader.getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/before?date=${date.toUtc().toIso8601String()}"),
      headers: headers,
    );
    _ensureOk(response);
    return (jsonDecode(response.body) as List)
        .map((e) => CaseJudgmentResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= DELETE =================
  static Future<bool> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");
    final userId = prefs.getString("userId");

    final response = await http.delete(
      Uri.parse("$baseUrl/$id?userId=$userId"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) return false;

    try {
      final body = jsonDecode(response.body);
      if (body is bool) return body;
    } catch (_) {}
    return true;
  }

  // ================= VIEW ATTACHMENT =================
  static Future<void> viewAttachment(String attachmentId) async {
    final headers = await AuthHeader.getHeaders();
    final url = Uri.parse("$baseUrl/attachment/view/$attachmentId");

    final response = await http.get(url, headers: headers);
    _ensureOk(response);

    final dir = await getTemporaryDirectory();
    final filePath = "${dir.path}/$attachmentId";

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    await OpenFile.open(file.path);
  }

  // ================= DOWNLOAD ATTACHMENT =================
  static Future<void> downloadAttachment(String attachmentId) async {
    final headers = await AuthHeader.getHeaders();
    final url = Uri.parse("$baseUrl/attachment/$attachmentId");

    final response = await http.get(url, headers: headers);
    _ensureOk(response);

    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/$attachmentId";

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    await OpenFile.open(file.path);
  }

  // ================= RAW URLS =================
  static String viewAttachmentUrl(String attachmentId) =>
      "$baseUrl/attachment/view/$attachmentId";

  static String downloadAttachmentUrl(String attachmentId) =>
      "$baseUrl/attachment/$attachmentId";

  // ================= HELPERS =================

  /// ✅ Works on both Web (bytes) and native (path). Must be awaited.
  static Future<void> _attachFileAsync(
      http.MultipartRequest request, PlatformFile? file) async {
    if (file == null) return;

    final mimeTypeStr = getMimeType(file.extension);
    final contentType =
        mimeTypeStr != null ? http.MediaType.parse(mimeTypeStr) : null;

    if (kIsWeb) {
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
            contentType: contentType,
          ),
        );
      }
    } else {
      if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
            contentType: contentType,
          ),
        );
      }
    }
  }

  static void _ensureOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String msg = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          msg = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(
        "CaseJudgmentService error ${response.statusCode}: $msg",
      );
    }
  }
}