import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import './AuthHeader.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'CaseJudgmentModel.dart';

class CaseJudgmentService {
  static  String baseUrl =
      "${BASE_URL.Urls().baseURL}case-judgment";

  static Future<http.Response> addJudgment({
    required String caseId,
    required String result,
    required String userId,
    File? file,
    DateTime? date,
  }) async {
    final uri = Uri.parse("$baseUrl/add");
    final headers = await AuthHeader.getHeaders();

    var request = http.MultipartRequest("POST", uri);
    request.headers.addAll(headers);

    request.fields['caseId'] = caseId;
    request.fields['result'] = result;
    request.fields['userId'] = userId;

    if (date != null) {
      request.fields['date'] = date.toUtc().toIso8601String();
    }

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: basename(file.path),
        ),
      );
    }

    final streamed = await request.send();
    return await http.Response.fromStream(streamed);
  }

  static Future<http.Response> updateJudgment({
    required String judgmentId,
    required String caseId,
    required String result,
    required String userId,
    String? oldAttachmentId,
    File? file,
    DateTime? date,
  }) async {
    final uri = Uri.parse("$baseUrl/update/$judgmentId");
    final headers = await AuthHeader.getHeaders();

    var request = http.MultipartRequest("PUT", uri);
    request.headers.addAll(headers);

    request.fields['caseId'] = caseId;
    request.fields['result'] = result;
    request.fields['userId'] = userId;

    if (oldAttachmentId != null) {
      request.fields['judgmentAttachmentId'] = oldAttachmentId;
    }

    if (date != null) {
      request.fields['date'] = date.toUtc().toIso8601String();
    }

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: basename(file.path),
        ),
      );
    }

    final streamed = await request.send();
    return await http.Response.fromStream(streamed);
  }

  static Future<CaseJudgment?> getByCase(String caseId) async {

    print("trying to fetch the judgment for case $caseId");

    final headers = await AuthHeader.getHeaders();
    final response = await http.get(
      Uri.parse("$baseUrl/case/$caseId"),
      headers: headers,
    );

    print("judgment fetching status :- ${response.statusCode}");

    if(response.statusCode == 200) {
      return CaseJudgment.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }

  }

  static Future<http.Response> getById(String id) async {
    final headers = await AuthHeader.getHeaders();
    return http.get(
      Uri.parse("$baseUrl/$id"),
      headers: headers,
    );
  }

  static Future<http.Response> getAll() async {
    final headers = await AuthHeader.getHeaders();
    return http.get(
      Uri.parse("$baseUrl/all"),
      headers: headers,
    );
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
}