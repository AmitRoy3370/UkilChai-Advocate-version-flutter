import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../Utils/BaseURL.dart' as BASE_URL;
import 'document_draft.dart';

class DocumentDraftService {
  final String token;

  DocumentDraftService(this.token);

  Map<String, String> get _headers => {"Authorization": "Bearer $token"};

  // ================= ADD DOCUMENT DRAFT =================
  Future<bool> addDraft({
    required String advocateId,
    required String caseId,
    required String userId,
    DateTime? issuedDate,
    List<PlatformFile>? files,
  }) async {
    final uri = Uri.parse("${BASE_URL.Urls().baseURL}document-draft/add");

    final request = http.MultipartRequest("POST", uri)
      ..headers.addAll(_headers)
      ..fields['advocateId'] = advocateId
      ..fields['caseId'] = caseId
      ..fields['userId'] = userId;

    if (issuedDate != null) {
      request.fields['issuedDate'] = issuedDate.toUtc().toIso8601String();
    }

    if (files != null) {
      for (final file in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
          ),
        );
      }
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  // ================= UPDATE DOCUMENT DRAFT =================
  Future<bool> updateDraft({
    required String draftId,
    required String advocateId,
    required String caseId,
    required String userId,
    DateTime? issuedDate,
    required List<String> existingFiles,
    List<PlatformFile>? newFiles,
  }) async {
    final uri = Uri.parse(
      "${BASE_URL.Urls().baseURL}document-draft/update/$draftId",
    );

    final request = http.MultipartRequest("PUT", uri)
      ..headers.addAll(_headers)
      ..fields['advocateId'] = advocateId
      ..fields['caseId'] = caseId
      ..fields['userId'] = userId
      ..fields['existingFiles'] = jsonEncode(existingFiles);

    if (issuedDate != null) {
      request.fields['issuedDate'] = issuedDate.toUtc().toIso8601String();
    }

    if (newFiles != null) {
      for (final file in newFiles) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
          ),
        );
      }
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  // ================= FIND BY ID =================
  Future<DocumentDraft> findById(String id) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}document-draft/$id"),
      headers: _headers,
    );

    return DocumentDraft.fromJson(jsonDecode(res.body));
  }

  // ================= FIND BY ADVOCATE =================
  Future<List<DocumentDraft>> findByAdvocate(String advocateId) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}document-draft/advocate/$advocateId",
      ),
      headers: _headers,
    );

    return (jsonDecode(res.body) as List)
        .map((e) => DocumentDraft.fromJson(e))
        .toList();
  }

  // ================= FIND BY CASE =================
  Future<DocumentDraft?> findByCase(String caseId) async {

    print("findByCase :- $caseId and with $token is trying to decode....");

    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}document-draft/case/$caseId"),
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("status code of findByCase :- ${res.statusCode}");

    if (res.statusCode == 200) {
      return DocumentDraft.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<bool> isDraft(String? caseId) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}document-draft/case/$caseId"),
      headers: _headers,
    );

    return res.statusCode == 200;
  }

  // ================= FIND ALL =================
  Future<List<DocumentDraft>> findAll() async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}document-draft/all"),
      headers: _headers,
    );

    return (jsonDecode(res.body) as List)
        .map((e) => DocumentDraft.fromJson(e))
        .toList();
  }

  // ================= DELETE =================
  Future<bool> deleteDraft(String id, String userId) async {
    final res = await http.delete(
      Uri.parse("${BASE_URL.Urls().baseURL}document-draft/$id?userId=$userId"),
      headers: _headers,
    );

    return res.statusCode == 200;
  }

  // ================= ATTACHMENT URLS =================
  String viewAttachmentUrl(String attachmentId) {
    return "${BASE_URL.Urls().baseURL}document-draft/attachment/view/$attachmentId";
  }

  String downloadAttachmentUrl(String attachmentId) {
    return "${BASE_URL.Urls().baseURL}document-draft/attachment/$attachmentId";
  }
}
