// DocumentDraftService.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../Utils/BaseURL.dart' as BASE_URL;
import 'document_draft.dart';

class DocumentDraftService {
  final String token;

  DocumentDraftService(this.token);

  Map<String, String> get _headers => {"Authorization": "Bearer $token"};

  // ================= MIME TYPE =================
  String? getMimeType(String? extension) {
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
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'application/octet-stream';
    }
  }

  // ================= ADD DOCUMENT DRAFT =================
  // POST /api/document-draft/add?userId=...
  Future<DocumentDraft> addDraft({
    required String advocateId,
    required String caseId,
    required String userId,
    DateTime? issuedDate,
    List<PlatformFile>? files,
  }) async {
    final uri = Uri.parse(
      "${BASE_URL.Urls().baseURL}document-draft/add?userId=$userId",
    );

    final request = http.MultipartRequest("POST", uri)
      ..headers.addAll(_headers)
      ..fields['advocateId'] = advocateId
      ..fields['caseId'] = caseId;

    if (issuedDate != null) {
      request.fields['issuedDate'] = issuedDate.toUtc().toIso8601String();
    }

    await _attachFiles(request, files);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureOk(response);

    return DocumentDraft.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ================= UPDATE DOCUMENT DRAFT =================
  // PUT /api/document-draft/update/{id}?userId=...
  Future<DocumentDraft> updateDraft({
    required String draftId,
    required String advocateId,
    required String caseId,
    required String userId,
    DateTime? issuedDate,
    required List<String> existingFiles,
    List<PlatformFile>? newFiles,
  }) async {
    final uri = Uri.parse(
      "${BASE_URL.Urls().baseURL}document-draft/update/$draftId?userId=$userId",
    );

    // ────────────────────────────────────────────────────────────
    // DEBUG: full request intro
    // ────────────────────────────────────────────────────────────
    debugPrint('══════════════════════════════════════════════════════════');
    debugPrint('🟦 UPDATEDRAFT — REQUEST');
    debugPrint('🟦 method        = PUT');
    debugPrint('🟦 url           = $uri');
    debugPrint('🟦 host          = ${uri.host}');
    debugPrint('🟦 path          = ${uri.path}');
    debugPrint('🟦 query         = ${uri.query}');
    debugPrint('🟦 userId (path) = $userId');
    debugPrint('🟦 draftId       = $draftId');
    debugPrint('🟦 advocateId    = $advocateId');
    debugPrint('🟦 caseId        = $caseId');
    debugPrint('🟦 issuedDate    = $issuedDate');
    debugPrint(
        '🟦 issuedDate UTC= ${issuedDate?.toUtc().toIso8601String()}');
    debugPrint(
        '🟦 existingFiles (${existingFiles.length}) = $existingFiles');
    debugPrint('🟦 newFiles count = ${newFiles?.length ?? 0}');
    if (newFiles != null && newFiles.isNotEmpty) {
      for (var i = 0; i < newFiles.length; i++) {
        final f = newFiles[i];
        debugPrint('🟦   newFiles[$i].name     = ${f.name}');
        debugPrint('🟦   newFiles[$i].size     = ${f.size}');
        debugPrint('🟦   newFiles[$i].extension= ${f.extension}');
        // ✅ FIX: `f.path` THROWS on Web. Guard it.
        debugPrint('🟦   newFiles[$i].path     = '
            '${kIsWeb ? "(web — no path)" : f.path}');
        debugPrint('🟦   newFiles[$i].bytes?   = ${f.bytes != null}'
            ' (${f.bytes?.length ?? 0} bytes)');
      }
    }

    final request = http.MultipartRequest("PUT", uri)
      ..headers.addAll(_headers)
      ..fields['advocateId'] = advocateId
      ..fields['caseId'] = caseId
      ..fields['existingFiles'] = jsonEncode(existingFiles);

    if (issuedDate != null) {
      request.fields['issuedDate'] = issuedDate.toUtc().toIso8601String();
    }

    // ────────────────────────────────────────────────────────────
    // DEBUG: auth headers & fields
    // ────────────────────────────────────────────────────────────
    debugPrint('🟦 --- REQUEST HEADERS ---');
    request.headers.forEach((k, v) {
      if (k.toLowerCase() == 'authorization') {
        final parts = v.split(' ');
        final token = parts.length == 2 ? parts[1] : v;
        final masked = token.length > 16
            ? '${token.substring(0, 8)}...'
                '${token.substring(token.length - 4)}'
                ' (len=${token.length})'
            : '(len=${token.length})';
        debugPrint('🟦   $k: Bearer $masked');
      } else {
        debugPrint('🟦   $k: $v');
      }
    });

    debugPrint('🟦 --- REQUEST FIELDS ---');
    request.fields.forEach((k, v) {
      if (k == 'existingFiles') {
        final shown = v.length > 200 ? '${v.substring(0, 200)}…' : v;
        debugPrint('🟦   $k: $shown');
      } else {
        debugPrint('🟦   $k: $v');
      }
    });

    // ────────────────────────────────────────────────────────────
    // Attach files
    // ────────────────────────────────────────────────────────────
    await _attachFiles(request, newFiles);

    debugPrint('🟦 --- MULTIPART FILES ATTACHED ---');
    debugPrint('🟦 files.length = ${request.files.length}');
    for (var i = 0; i < request.files.length; i++) {
      final mf = request.files[i];
      debugPrint('🟦   file[$i].field    = ${mf.field}');
      debugPrint('🟦   file[$i].filename = ${mf.filename}');
      debugPrint('🟦   file[$i].length   = ${mf.length}');
      debugPrint('🟦   file[$i].type     = ${mf.contentType}');
    }

    // ────────────────────────────────────────────────────────────
    // Send
    // ────────────────────────────────────────────────────────────
    debugPrint('🟦 --- SENDING REQUEST ---');
    final streamed = await request.send();
    debugPrint('🟦 streamed.statusCode = ${streamed.statusCode}');
    debugPrint('🟦 streamed.reason     = ${streamed.reasonPhrase}');
    debugPrint('🟦 streamed.headers    = ${streamed.headers}');
    debugPrint('🟦 streamed.isRedirect = ${streamed.isRedirect}');
    debugPrint(
        '🟦 streamed.persistent = ${streamed.persistentConnection}');

    final response = await http.Response.fromStream(streamed);

    debugPrint('🟦 --- RESPONSE ---');
    debugPrint('🟦 statusCode = ${response.statusCode}');
    debugPrint('🟦 reason     = ${response.reasonPhrase}');
    debugPrint('🟦 headers:');
    response.headers.forEach((k, v) {
      debugPrint('🟦   $k: $v');
    });
    debugPrint('🟦 body.length = ${response.body.length}');
    debugPrint('🟦 body        = ${response.body}');

    // ────────────────────────────────────────────────────────────
    // Ensure OK — catch and print the exception with context
    // ────────────────────────────────────────────────────────────
    try {
      _ensureOk(response);
    } catch (e) {
      debugPrint('🟥 _ensureOk THREW: $e');
      debugPrint('🟥 FULL URL WAS: $uri');
      debugPrint('🟥 SENT userId: $userId');
      debugPrint('🟥 SENT advocateId: $advocateId');
      debugPrint('🟥 SENT caseId: $caseId');
      debugPrint(
          '🟥 SENT existingFiles length: ${existingFiles.length}');
      debugPrint(
          '🟥 SENT newFiles length: ${newFiles?.length ?? 0}');
      debugPrint('🟥 RESPONSE status: ${response.statusCode}');
      debugPrint('🟥 RESPONSE body  : "${response.body}"');
      debugPrint('══════════════════════════════════════════════════════════');
      rethrow;
    }

    debugPrint('🟩 UPDATEDRAFT — SUCCESS status=${response.statusCode}');
    debugPrint('══════════════════════════════════════════════════════════');

    return DocumentDraft.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ================= FIND BY ID =================
  // GET /api/document-draft/{id}
  Future<DocumentDraftResponse> findById(String id) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}document-draft/$id"),
      headers: _headers,
    );
    _ensureOk(res);

    return DocumentDraftResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ================= FIND BY ADVOCATE =================
  // GET /api/document-draft/advocate/{advocateId}
  Future<List<DocumentDraftResponse>> findByAdvocate(
      String advocateId) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}document-draft/advocate/$advocateId",
      ),
      headers: _headers,
    );
    _ensureOk(res);

    return (jsonDecode(res.body) as List)
        .map((e) => DocumentDraftResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= FIND BY CASE =================
  // GET /api/document-draft/case/{caseId}
  Future<DocumentDraftResponse?> findByCase(String caseId) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}document-draft/case/$caseId"),
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      return DocumentDraftResponse.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    if (res.statusCode == 404) return null;

    _ensureOk(res);
    return null;
  }

  // ================= IS DRAFT? =================
  Future<bool> isDraft(String? caseId) async {
    if (caseId == null) return false;

    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}document-draft/case/$caseId"),
      headers: _headers,
    );

    return res.statusCode == 200;
  }

  // ================= AFTER DATE =================
  Future<List<DocumentDraftResponse>> findAfter(DateTime date) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}document-draft/after?date=${date.toUtc().toIso8601String()}",
      ),
      headers: _headers,
    );
    _ensureOk(res);

    return (jsonDecode(res.body) as List)
        .map((e) => DocumentDraftResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= BEFORE DATE =================
  Future<List<DocumentDraftResponse>> findBefore(DateTime date) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}document-draft/before?date=${date.toUtc().toIso8601String()}",
      ),
      headers: _headers,
    );
    _ensureOk(res);

    return (jsonDecode(res.body) as List)
        .map((e) => DocumentDraftResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= FIND ALL =================
  Future<List<DocumentDraftResponse>> findAll() async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}document-draft/all"),
      headers: _headers,
    );
    _ensureOk(res);

    return (jsonDecode(res.body) as List)
        .map((e) => DocumentDraftResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ================= DELETE =================
  Future<bool> deleteDraft(String id, String userId) async {
    final res = await http.delete(
      Uri.parse("${BASE_URL.Urls().baseURL}document-draft/$id?userId=$userId"),
      headers: _headers,
    );

    if (res.statusCode != 200) return false;

    try {
      final body = jsonDecode(res.body);
      if (body is bool) return body;
    } catch (_) {}
    return true;
  }

  // ================= VIEW ATTACHMENT (download + open) =================
  Future<void> viewAttachment(String attachmentId) async {
    final url = Uri.parse(
      "${BASE_URL.Urls().baseURL}document-draft/attachment/view/$attachmentId",
    );

    final response = await http.get(url, headers: _headers);
    _ensureOk(response);

    final dir = await getTemporaryDirectory();
    final filePath = "${dir.path}/$attachmentId";

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    await OpenFile.open(file.path);
  }

  // ================= DOWNLOAD ATTACHMENT =================
  Future<void> downloadAttachment(String attachmentId) async {
    final url = Uri.parse(
      "${BASE_URL.Urls().baseURL}document-draft/attachment/$attachmentId",
    );

    final response = await http.get(url, headers: _headers);
    _ensureOk(response);

    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/$attachmentId";

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    await OpenFile.open(file.path);
  }

  // ================= RAW ATTACHMENT URLS =================
  String viewAttachmentUrl(String attachmentId) {
    return "${BASE_URL.Urls().baseURL}document-draft/attachment/view/$attachmentId";
  }

  String downloadAttachmentUrl(String attachmentId) {
    return "${BASE_URL.Urls().baseURL}document-draft/attachment/$attachmentId";
  }

  // ================= HELPERS =================

  /// Attaches files from the picked list. Never throws:
  /// - Web: uses `bytes` (must be non-null; `withData: true` on the picker).
  /// - Native: uses `path`.
  /// Any file missing the required property is silently skipped with a log.
  Future<void> _attachFiles(
      http.MultipartRequest request, List<PlatformFile>? files) async {
    if (files == null || files.isEmpty) return;

    for (final file in files) {
      final mimeTypeStr = getMimeType(file.extension);
      final contentType =
          mimeTypeStr != null ? http.MediaType.parse(mimeTypeStr) : null;

      if (kIsWeb) {
        // ✅ Never touch `file.path` on Web — it throws.
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          debugPrint(
              '⚠️ Skipping web file with null/empty bytes: ${file.name}');
          continue;
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            bytes,
            filename: file.name,
            contentType: contentType,
          ),
        );
      } else {
        final path = file.path;
        if (path == null || path.isEmpty) {
          debugPrint(
              '⚠️ Skipping native file with null/empty path: ${file.name}');
          continue;
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            path,
            filename: file.name,
            contentType: contentType,
          ),
        );
      }
    }
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "DocumentDraftService error ${response.statusCode}: ${response.body}",
      );
    }
  }
}