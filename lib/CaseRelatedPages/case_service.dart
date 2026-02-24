import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:advocatechaiadvocate/CaseRelatedPages/case_model.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASE_URL;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';


class CaseService {
  final String token;

  CaseService(this.token);

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token") ?? "";
  }

  Map<String, String> get _headers => {
    "Authorization": "Bearer $token",
  };

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
      default:
        return 'application/octet-stream';
    }
  }

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
    final uri = Uri.parse("${BASE_URL.Urls().baseURL}case/update");

    final request = http.MultipartRequest("POST", uri)
      ..headers.addAll(_headers)
      ..fields['caseId'] = caseId
      ..fields['caseName'] = caseName
      ..fields['userId'] = userId
      ..fields['advocateId'] = advocateId
      ..fields['caseType'] = caseType
      ..fields['usersId'] = usersId
      ..fields['existingFiles'] = jsonEncode(existingFiles);

    print("existing files :- ${request.fields["existingFiles"]}");

    if (newFiles.isNotEmpty) {
      for (final f in newFiles) {

        String? extension = f.extension;

        final mimeTypeStr = getMimeType(extension);
        http.MediaType? contentType = mimeTypeStr != null ? http.MediaType.parse(mimeTypeStr) : null;


        if (f.bytes != null) {
          // WEB
          request.files.add(
            http.MultipartFile.fromBytes("files", f.bytes!, filename: f.name, contentType: contentType),
          );
        } else if (f.path != null) {
          // ANDROID / IOS
          request.files.add(
            await http.MultipartFile.fromPath("files", f.path!, contentType: contentType),
          );
        }
      }
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  // ================= FIND BY ID =================
  Future<CaseModel> findById(String id) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}case/$id"),
      headers: _headers,
    );

    final body = jsonDecode(res.body);
    return CaseModel.fromJson(body['data']);
  }

  // ================= FIND ALL =================
  Future<List<CaseModel>> findAll() async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}case/all"),
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
      Uri.parse("${BASE_URL.Urls().baseURL}case/user/$userId"),
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
      Uri.parse("${BASE_URL.Urls().baseURL}case/search/$name"),
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
      Uri.parse("${BASE_URL.Urls().baseURL}case/$caseId/$userId"),
      headers: _headers,
    );

    return res.statusCode == 200;
  }

  // ================= ATTACHMENT URLS =================
  String viewAttachmentUrl(String attachmentId) {
    return "${BASE_URL.Urls().baseURL}case/attachment/view/$attachmentId";
  }

  String downloadAttachmentUrl(String attachmentId) {
    return "${BASE_URL.Urls().baseURL}case/attachment/$attachmentId";
  }

  Future<bool> deleteAttachment(String attachmentId) async {
    final res = await http.delete(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}case/attachment/$attachmentId",
      ),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    return res.statusCode == 200;
  }

}
