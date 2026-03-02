import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './AuthHeader.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'CaseJudgmentModel.dart';

class CaseJudgmentService {
  static String baseUrl = "${BASE_URL.Urls().baseURL}case-judgment";

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

  static Future<http.Response> addJudgment({
    required String caseId,
    required String result,
    required String userId,
    PlatformFile? file,
    DateTime? date,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");

    print("generated token :- $token");
    print("token length: ${token?.length}");

    final uri = Uri.parse("$baseUrl/add?userId=$userId");

    print("requested url for add is :- ${uri.toString()}");

    print("requested user id for add in this case :- $userId");
    print("declared result :- $result");
    print("declared caseId :- $caseId");
    print("date: $date");

    final headers = {
      'Authorization': 'Bearer $token',
      "Content-Type": "multipart/form-data"
      // Don't set content-type - it will be set automatically with boundary
    };

    var request = http.MultipartRequest("POST", uri);
    request.headers['Authorization'] = 'Bearer $token';

    // Add ALL fields as MultipartFile parts, NOT as fields
    request.fields['caseId'] = caseId;
    request.fields['result'] = result;

    if (date != null) {

      request.fields['date'] = date.toUtc().toIso8601String();

    }

    // Add file if present
    if (file != null && file.bytes != null) {
      final mimeTypeStr = getMimeType(file.extension);
      http.MediaType? contentType = mimeTypeStr != null
          ? http.MediaType.parse(mimeTypeStr)
          : null;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
            contentType: contentType,
          ),
        );
      } else {
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

    print("total parts in request: ${request.files.length}");
    for (var file in request.files) {
      print("part: ${file.field}, filename: ${file.filename}");
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print("response status code: ${response.statusCode}");
    print("response body: ${response.body}");

    return response;
  }

  static Future<http.Response> updateJudgment({
    required String judgmentId,
    required String caseId,
    required String result,
    required String userId,
    String? oldAttachmentId,
    PlatformFile? file,
    DateTime? date,
  }) async {
    final uri = Uri.parse("$baseUrl/update/$judgmentId?userId=$userId");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");

    print("update - token: $token");
    print("update - judgmentId: $judgmentId");
    print("update - caseId: $caseId");
    print("update - result: $result");
    print("update - userId: $userId");
    print("update - oldAttachmentId: $oldAttachmentId");
    print("update - date: $date");

    final headers = {
      'Authorization': 'Bearer $token',
    };

    var request = http.MultipartRequest("PUT", uri);
    request.headers['Authorization'] = 'Bearer $token';

    // Add ALL fields as MultipartFile parts, NOT as fields
    request.fields['caseId'] = caseId;
    request.fields['result'] = result;


    if (oldAttachmentId != null && oldAttachmentId.isNotEmpty) {
      request.fields['judgmentAttachmentId'] = oldAttachmentId;
    }

    if (date != null) {

      request.fields['date'] = date.toUtc().toIso8601String();

    }

    // Add file if present
    if (file != null && file.bytes != null) {
      final mimeTypeStr = getMimeType(file.extension);
      http.MediaType? contentType = mimeTypeStr != null
          ? http.MediaType.parse(mimeTypeStr)
          : null;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
            contentType: contentType,
          ),
        );
      } else {
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

    print("update - total parts: ${request.files.length}");

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print("update - response status: ${response.statusCode}");
    print("update - response body: ${response.body}");

    return response;
  }

  static Future<CaseJudgment?> getByCase(String caseId) async {
    print("trying to fetch the judgment for case $caseId");

    final headers = await AuthHeader.getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/case/$caseId"),
      headers: headers,
    );

    print("judgment fetching status :- ${response.statusCode}");

    if (response.statusCode == 200) {
      return CaseJudgment.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }

  static Future<http.Response> getById(String id) async {
    final headers = await AuthHeader.getHeaders();
    return http.get(Uri.parse("$baseUrl/$id"), headers: headers);
  }

  static Future<http.Response> getAll() async {
    final headers = await AuthHeader.getHeaders();
    return http.get(Uri.parse("$baseUrl/all"), headers: headers);
  }

  static Future<http.Response> searchByResult(String result) async {
    final headers = await AuthHeader.getHeaders();
    return http.get(
      Uri.parse("$baseUrl/search?result=$result"),
      headers: headers,
    );
  }

  static Future<http.Response> afterDate(DateTime date) async {
    final headers = await AuthHeader.getHeaders();
    return http.get(
      Uri.parse("$baseUrl/after?date=${date.toUtc().toIso8601String()}"),
      headers: headers,
    );
  }

  static Future<http.Response> beforeDate(DateTime date) async {
    final headers = await AuthHeader.getHeaders();
    return http.get(
      Uri.parse("$baseUrl/before?date=${date.toUtc().toIso8601String()}"),
      headers: headers,
    );
  }

  static Future<http.Response> remove(String id) async {
    final headers = await AuthHeader.getHeaders();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");
    final userId = prefs.getString("userId");

    final response = await http.delete(
      Uri.parse("$baseUrl/$id?userId=$userId"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response;
  }
}
