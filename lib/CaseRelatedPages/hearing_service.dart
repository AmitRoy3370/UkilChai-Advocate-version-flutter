import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'HearingModel.dart';

class HearingService {
  static String baseUrl = "${BASE_URL.Urls().baseURL.replaceFirst('/api/', '/')}hearing";

  // ================= AUTH HEADER =================
  static Map<String, String> authHeader(String token) {
    return {
      "Authorization": "Bearer $token",
    };
  }

  // ================= ADD HEARING =================
  static Future<http.Response> addHearing({
    required String token,
    required String userId,
    required String caseId,
    required int hearingNumber,
    DateTime? issuedDate,
    List<File>? files,
  }) async {
    final uri = Uri.parse("$baseUrl/add/$userId");
    final request = http.MultipartRequest("POST", uri);

    request.headers.addAll(authHeader(token));
    request.fields['caseId'] = caseId;
    request.fields['hearningNumber'] = hearingNumber.toString();

    if (issuedDate != null) {
      request.fields['issuedDate'] = issuedDate.toUtc().toIso8601String();
    }

    if (files != null) {
      for (var file in files) {
        request.files.add(
          await http.MultipartFile.fromPath("files", file.path),
        );
      }
    }

    final response = await request.send();
    return http.Response.fromStream(response);
  }

  // ================= UPDATE HEARING =================
  static Future<http.Response> updateHearing({
    required String token,
    required String hearingId,
    required String userId,
    required String caseId,
    required int hearingNumber,
    DateTime? issuedDate,
    List<String>? existingFiles,
    List<File>? newFiles,
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

    if (newFiles != null) {
      for (var file in newFiles) {
        request.files.add(
          await http.MultipartFile.fromPath("files", file.path),
        );
      }
    }

    final response = await request.send();
    return http.Response.fromStream(response);
  }

  // ================= GET BY CASE =================
  static Future<List<Hearing>> getByCase(
      String token, String caseId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/case/$caseId"),
      headers: authHeader(token),
    );

    final List data = jsonDecode(response.body);
    return data.map((e) => Hearing.fromJson(e)).toList();
  }

  // ================= VIEW ATTACHMENT =================
  static Future<void> viewAttachment(
      String token, String attachmentId) async {
    final url = Uri.parse("$baseUrl/attachment/view/$attachmentId");

    final response =
    await http.get(url, headers: authHeader(token));

    final dir = await getTemporaryDirectory();
    final filePath = "${dir.path}/$attachmentId";

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    OpenFile.open(file.path);
  }

  // ================= DOWNLOAD ATTACHMENT =================
  static Future<void> downloadAttachment(
      String token, String attachmentId) async {
    final url = Uri.parse("$baseUrl/attachment/$attachmentId");

    final response =
    await http.get(url, headers: authHeader(token));

    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/$attachmentId";

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    OpenFile.open(file.path);
  }
}
