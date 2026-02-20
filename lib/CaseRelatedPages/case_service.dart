import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:advocatechaiadvocate/CaseRelatedPages/case_model.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASE_URL;

class CaseService {
  final String token;

  CaseService(this.token);

  Map<String, String> get _headers => {
    "Authorization": "Bearer $token",
  };

  // ================= UPDATE CASE =================
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
    final uri = Uri.parse("${BASE_URL.Urls().baseURL}/case/update");

    final request = http.MultipartRequest("POST", uri)
      ..headers.addAll(_headers)
      ..fields['caseId'] = caseId
      ..fields['caseName'] = caseName
      ..fields['userId'] = userId
      ..fields['advocateId'] = advocateId
      ..fields['caseType'] = caseType
      ..fields['usersId'] = usersId
      ..fields['existingFiles'] = jsonEncode(existingFiles);

    for (final file in newFiles) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          file.bytes!,
          filename: file.name,
        ),
      );
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  // ================= FIND BY ID =================
  Future<CaseModel> findById(String id) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}/case/$id"),
      headers: _headers,
    );

    final body = jsonDecode(res.body);
    return CaseModel.fromJson(body['data']);
  }

  // ================= FIND ALL =================
  Future<List<CaseModel>> findAll() async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}/case/all"),
      headers: _headers,
    );

    final body = jsonDecode(res.body);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e))
        .toList();
  }

  // ================= BY USER =================
  Future<List<CaseModel>> byUser(String userId) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}/case/user/$userId"),
      headers: _headers,
    );

    final body = jsonDecode(res.body);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e))
        .toList();
  }

  // ================= SEARCH =================
  Future<List<CaseModel>> search(String name) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}/case/search/$name"),
      headers: _headers,
    );

    final body = jsonDecode(res.body);
    return (body['data'] as List)
        .map((e) => CaseModel.fromJson(e))
        .toList();
  }

  // ================= DELETE =================
  Future<bool> deleteCase(String caseId, String userId) async {
    final res = await http.delete(
      Uri.parse("${BASE_URL.Urls().baseURL}/case/$caseId/$userId"),
      headers: _headers,
    );

    return res.statusCode == 200;
  }

  // ================= ATTACHMENT URLS =================
  String viewAttachmentUrl(String attachmentId) {
    return "${BASE_URL.Urls().baseURL}/case/attachment/view/$attachmentId";
  }

  String downloadAttachmentUrl(String attachmentId) {
    return "${BASE_URL.Urls().baseURL}/case/attachment/$attachmentId";
  }
}
