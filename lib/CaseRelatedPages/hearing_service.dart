import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import '../CaseRelatedPages/case_model.dart';
import 'HearingModel.dart';
import 'package:flutter/foundation.dart';

class HearingService {
  static String baseUrl =
      "${BASE_URL.Urls().baseURL.replaceFirst('/api/', '/')}hearing";

  // ================= AUTH HEADER =================
  static Map<String, String> authHeader(String token) {
    return {
      "Authorization": "Bearer $token",
    };
  }

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
  // POST /hearing/add/{userId}
  static Future<http.Response> addHearing({
    required String token,
    required String userId,
    required String caseId,
    required int hearingNumber,
    DateTime? issuedDate,
    List<PlatformFile>? files,
  }) async {
    final uri = Uri.parse("$baseUrl/add/$userId");
    final request = http.MultipartRequest("POST", uri);

    request.headers.addAll(authHeader(token));
    request.fields['caseId'] = caseId;
    request.fields['hearningNumber'] = hearingNumber.toString();

    if (issuedDate != null) {
      request.fields['issuedDate'] = issuedDate.toUtc().toIso8601String();
    }

    await _attachFiles(request, files);

    final response = await request.send();
    return http.Response.fromStream(response);
  }

  // ================= UPDATE =================
  // PUT /hearing/update/{hearingId}/{userId}
  static Future<http.Response> updateHearing({
    required String token,
    required String hearingId,
    required String userId,
    required String caseId,
    required int hearingNumber,
    DateTime? issuedDate,
    List<String>? existingFiles,
    List<PlatformFile>? files,
  }) async {
    final uri = Uri.parse("$baseUrl/update/$hearingId/$userId");
    final request = http.MultipartRequest("PUT", uri);

    request.headers.addAll(authHeader(token));
    request.fields['caseId'] = caseId;
    request.fields['hearningNumber'] = hearingNumber.toString();

    if (issuedDate != null) {
      request.fields['issuedDate'] = issuedDate.toUtc().toIso8601String();
    }

    if (existingFiles != null) {
      request.fields['existingFiles'] = jsonEncode(existingFiles);
    }

    await _attachFiles(request, files);

    final response = await request.send();
    return http.Response.fromStream(response);
  }

  // ================= GET BY CASE =================
  // GET /hearing/case/{caseId}
  static Future<List<HearingResponse>> getByCase(
      String token, String caseId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/case/$caseId"),
      headers: authHeader(token),
    );
    _ensureOk(response);

    final List data = jsonDecode(response.body);
    return data
        .map((e) => HearingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= GET BY HEARING NUMBER =================
  // GET /hearing/number/{num}
  static Future<List<HearingResponse>> getByNumber(
      String token, int number) async {
    final response = await http.get(
      Uri.parse("$baseUrl/number/$number"),
      headers: authHeader(token),
    );
    _ensureOk(response);

    final List data = jsonDecode(response.body);
    return data
        .map((e) => HearingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= GET BY CASE + NUMBER =================
  // GET /hearing/case/{caseId}/number/{num}
  static Future<HearingResponse> getByCaseAndNumber(
      String token, String caseId, int number) async {
    final response = await http.get(
      Uri.parse("$baseUrl/case/$caseId/number/$number"),
      headers: authHeader(token),
    );
    _ensureOk(response);

    return HearingResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ================= GET UP TO NUMBER =================
  // GET /hearing/case/{caseId}/upto/{num}
  static Future<List<HearingResponse>> getUpTo(
      String token, String caseId, int number) async {
    final response = await http.get(
      Uri.parse("$baseUrl/case/$caseId/upto/$number"),
      headers: authHeader(token),
    );
    _ensureOk(response);

    final List data = jsonDecode(response.body);
    return data
        .map((e) => HearingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= AFTER DATE =================
  // GET /hearing/after?date=...
  static Future<List<HearingResponse>> getAfter(
      String token, DateTime date) async {
    final response = await http.get(
      Uri.parse("$baseUrl/after?date=${date.toUtc().toIso8601String()}"),
      headers: authHeader(token),
    );
    _ensureOk(response);

    final List data = jsonDecode(response.body);
    return data
        .map((e) => HearingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= BEFORE DATE =================
  // GET /hearing/before?date=...
  static Future<List<HearingResponse>> getBefore(
      String token, DateTime date) async {
    final response = await http.get(
      Uri.parse("$baseUrl/before?date=${date.toUtc().toIso8601String()}"),
      headers: authHeader(token),
    );
    _ensureOk(response);

    final List data = jsonDecode(response.body);
    return data
        .map((e) => HearingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= ALL =================
  // GET /hearing/all
  static Future<List<HearingResponse>> getAll(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/all"),
      headers: authHeader(token),
    );
    _ensureOk(response);

    final List data = jsonDecode(response.body);
    return data
        .map((e) => HearingResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= BY ID =================
  // GET /hearing/{id}
  static Future<HearingResponse> getById(String token, String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: authHeader(token),
    );
    _ensureOk(response);

    return HearingResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ================= VIEW ATTACHMENT =================
  // GET /hearing/attachment/view/{attachmentId}
  static Future<void> viewAttachment(
      String token, String attachmentId) async {
    final url = Uri.parse("$baseUrl/attachment/view/$attachmentId");

    final response = await http.get(url, headers: authHeader(token));
    _ensureOk(response);

    final dir = await getTemporaryDirectory();
    final filePath = "${dir.path}/$attachmentId";

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    await OpenFile.open(file.path);
  }

  // ================= DOWNLOAD ATTACHMENT =================
  // GET /hearing/attachment/{attachmentId}
  static Future<void> downloadAttachment(
      String token, String attachmentId) async {
    final url = Uri.parse("$baseUrl/attachment/$attachmentId");

    final response = await http.get(url, headers: authHeader(token));
    _ensureOk(response);

    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/$attachmentId";

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    await OpenFile.open(file.path);
  }

  // ================= DELETE =================
  // DELETE /hearing/{id}/{userId}
  static Future<bool> removeHearing(
      String token, String hearingId, String userId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/$hearingId/$userId"),
      headers: authHeader(token),
    );

    if (response.statusCode != 200) return false;

    // Backend returns `true`/`false` boolean as body
    try {
      final body = jsonDecode(response.body);
      if (body is bool) return body;
    } catch (_) {}
    return true;
  }

  // ================= HELPERS =================

  /// Attaches files (works both on web and mobile).
  static Future<void> _attachFiles(
      http.MultipartRequest request, List<PlatformFile>? files) async {
    if (files == null) return;

    for (final file in files) {
      final mimeTypeStr = getMimeType(file.extension);
      final contentType = mimeTypeStr != null
          ? http.MediaType.parse(mimeTypeStr)
          : null;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
            contentType: contentType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            file.path!,
            filename: file.name,
            contentType: contentType,
          ),
        );
      }
    }
  }

  /// Throws a readable exception when the backend returns an error.
  static void _ensureOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = response.body;
      try {
        final map = jsonDecode(response.body);
        message = map['message']?.toString() ?? message;
      } catch (_) {}
      throw Exception("HearingService error ${response.statusCode}: $message");
    }
  }
}