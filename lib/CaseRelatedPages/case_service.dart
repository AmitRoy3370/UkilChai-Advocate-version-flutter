// lib/CaseRelatedPages/case_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';           // MediaType
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASE_URL;
import 'package:advocatechaiadvocate/CaseRelatedPages/case_model.dart';

class CaseService {
  /// If provided, this token is used; otherwise we read from SharedPreferences.
  final String? token;

  CaseService([this.token]);

  // ---------- helpers ----------

  Future<String> _resolveToken() async {
    if (token != null && token!.isNotEmpty) return token!;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token") ?? "";
  }

  Future<Map<String, String>> _headers() async => {
        "Authorization": "Bearer ${await _resolveToken()}",
        "Accept": "application/json",
      };

  String _base() => BASE_URL.Urls().baseURL;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse("${_base()}$path");
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }

  /// Decode a JSON body with a check for `success == false`.
  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? "{}" : res.body;
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded["success"] == false) {
      throw Exception(decoded["error"]?.toString() ?? "Unknown server error");
    }
    return decoded;
  }

  // ---------- mime types ----------

  String? getMimeType(String? extension) {
    if (extension == null) return null;
    switch (extension.toLowerCase()) {
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

  // =========================================================================
  // ======================= UPDATE CASE (multipart) =========================
  // =========================================================================
  Future<bool> updateCase({
    required String caseId,
    required String caseName,
    required String userId,
    required String advocateId,
    required String caseType,
    required String usersId,
    required List<String> existingFiles,
    required List<PlatformFile> newFiles,
  }) async {
    final uri = _uri("case/update");
    debugPrint("[CaseService] updateCase -> $uri");

    final request = http.MultipartRequest("POST", uri)
      ..headers["Authorization"] = "Bearer ${await _resolveToken()}"
      ..fields['caseId'] = caseId
      ..fields['caseName'] = caseName
      ..fields['userId'] = userId
      ..fields['advocateId'] = advocateId
      ..fields['caseType'] = caseType
      ..fields['usersId'] = usersId
      ..fields['existingFiles'] = jsonEncode(existingFiles);

    for (final f in newFiles) {
      final mimeStr = getMimeType(f.extension);
      final contentType = mimeStr != null ? MediaType.parse(mimeStr) : null;

      if (f.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          "files",
          f.bytes!,
          filename: f.name,
          contentType: contentType,
        ));
      } else if (f.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          "files",
          f.path!,
          contentType: contentType,
        ));
      }
    }

    final response = await request.send();
    debugPrint("[CaseService] updateCase status=${response.statusCode}");
    return response.statusCode == 200;
  }

  // =========================================================================
  // =========================== SIMPLE GETTERS ==============================
  // =========================================================================
  Future<CaseModel> findById(String id) async {
    final res = await http.get(_uri("case/$id"), headers: await _headers());
    final body = _decode(res);
    return CaseModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<CaseModel>> findAll() async {
    final res = await http.get(_uri("case/all"), headers: await _headers());
    final body = _decode(res);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CaseModel>> byUser(String userId) async {
    final res =
        await http.get(_uri("case/user/$userId"), headers: await _headers());
    final body = _decode(res);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CaseModel>> byAdvocate(String advocateId) async {
    final res = await http.get(_uri("case/advocate/$advocateId"),
        headers: await _headers());
    final body = _decode(res);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CaseModel>> byType(String type) async {
    final res = await http.get(_uri("case/type/$type"),
        headers: await _headers());
    final body = _decode(res);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CaseModel>> byName(String caseName) async {
    final res = await http.get(_uri("case/name/$caseName"),
        headers: await _headers());
    final body = _decode(res);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CaseModel>> search(String name) async {
    final res =
        await http.get(_uri("case/search/$name"), headers: await _headers());
    final body = _decode(res);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CaseModel>> after(DateTime time) async {
    final res = await http.get(
      _uri("case/after", {"time": time.toUtc().toIso8601String()}),
      headers: await _headers(),
    );
    final body = _decode(res);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CaseModel>> before(DateTime time) async {
    final res = await http.get(
      _uri("case/before", {"time": time.toUtc().toIso8601String()}),
      headers: await _headers(),
    );
    final body = _decode(res);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // =========================================================================
  // ========================== PAGINATED GETTERS ============================
  // =========================================================================

  /// Backend default for Spring `Pageable` is page=0, size=20 unless specified.
  /// Pass `page` and `size` explicitly to control paging.
  Future<CasePageModel> _pagedGet(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await http.get(
      _uri(path, query),
      headers: await _headers(),
    );
    final body = _decode(res);
    return CasePageModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<CasePageModel> searchPaginated(
    String name, {
    int page = 0,
    int size = 20,
  }) =>
      _pagedGet("case/search/paginated/$name",
          query: {"page": page, "size": size});

  Future<CasePageModel> byUserPaginated(
    String userId, {
    int page = 0,
    int size = 20,
  }) =>
      _pagedGet("case/user/paginated/$userId",
          query: {"page": page, "size": size});

  Future<CasePageModel> byTypePaginated(
    String type, {
    int page = 0,
    int size = 20,
  }) =>
      _pagedGet("case/type/paginated/$type",
          query: {"page": page, "size": size});

  Future<CasePageModel> byAdvocatePaginated(
    String advocateId, {
    int page = 0,
    int size = 20,
  }) =>
      _pagedGet("case/advocate/paginated/$advocateId",
          query: {"page": page, "size": size});

  Future<CasePageModel> afterPaginated(
    DateTime time, {
    int page = 0,
    int size = 20,
  }) =>
      _pagedGet("case/after/paginated", query: {
        "time": time.toUtc().toIso8601String(),
        "page": page,
        "size": size,
      });

  Future<CasePageModel> beforePaginated(
    DateTime time, {
    int page = 0,
    int size = 20,
  }) =>
      _pagedGet("case/before/paginated", query: {
        "time": time.toUtc().toIso8601String(),
        "page": page,
        "size": size,
      });

  Future<CasePageModel> allPaginated({
    int page = 0,
    int size = 20,
  }) =>
      _pagedGet("case/all/paginated", query: {
        "page": page,
        "size": size,
      });

  // =========================================================================
  // ============================== DELETE ===================================
  // =========================================================================
  Future<bool> deleteCase(String caseId, String userId) async {
    final res = await http.delete(
      _uri("case/$caseId/$userId"),
      headers: await _headers(),
    );
    return res.statusCode == 200;
  }

  // =========================================================================
  // ========================= ATTACHMENT HELPERS ============================
  // =========================================================================

  /// URL to view an attachment inline (opens in browser / image viewer).
  /// Matches backend GET /api/case/attachment/view/{attachmentId}
  String viewAttachmentUrl(String attachmentId) =>
      "${_base()}case/attachment/view/$attachmentId";

  /// URL to download an attachment (Content-Disposition: attachment).
  /// Matches backend GET /api/case/attachment/{attachmentId}
  String downloadAttachmentUrl(String attachmentId) =>
      "${_base()}case/attachment/$attachmentId";

  /// DELETE an attachment by id. Note: your backend `CaseController`
  /// currently does NOT expose this route — if you add
  /// `@DeleteMapping("/attachment/{attachmentId}")` server-side, this
  /// will work automatically.
  Future<bool> deleteAttachment(String attachmentId) async {
    final res = await http.delete(
      _uri("case/attachment/$attachmentId"),
      headers: await _headers(),
    );
    return res.statusCode == 200;
  }

  /// Convenience: download an attachment into memory (for previews).
  /// Returns null if the request fails.
  Future<Uint8List?> fetchAttachmentBytes(String attachmentId) async {
    try {
      final res = await http.get(
        Uri.parse(viewAttachmentUrl(attachmentId)),
        headers: await _headers(),
      );
      if (res.statusCode == 200) return res.bodyBytes;
      return null;
    } catch (e) {
      debugPrint("[CaseService] fetchAttachmentBytes error: $e");
      return null;
    }
  }

  /// Convenience: save an attachment to a temp file (useful on mobile).
  /// Returns the local file path, or null if it failed.
  Future<String?> downloadAttachmentToFile(String attachmentId,
      {String? fileName}) async {
    try {
      final res = await http.get(
        Uri.parse(downloadAttachmentUrl(attachmentId)),
        headers: await _headers(),
      );
      if (res.statusCode != 200) return null;

      final dir = Directory.systemTemp;
      final file = File(
        "${dir.path}/${fileName ?? "attachment_$attachmentId"}",
      );
      await file.writeAsBytes(res.bodyBytes);
      return file.path;
    } catch (e) {
      debugPrint("[CaseService] downloadAttachmentToFile error: $e");
      return null;
    }
  }
}