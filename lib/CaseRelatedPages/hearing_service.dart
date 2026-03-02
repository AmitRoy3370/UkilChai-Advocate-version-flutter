
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'HearingModel.dart';
import 'package:flutter/foundation.dart';

class HearingService {
  static String baseUrl = "${BASE_URL.Urls().baseURL.replaceFirst('/api/', '/')}hearing";

  // ================= AUTH HEADER =================
  static Map<String, String> authHeader(String token) {
    return {
      "Authorization": "Bearer $token",
    };
  }


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


  // ================= ADD HEARING =================
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

    if (files != null) {
      for (final file in files) {
        final mimeTypeStr = getMimeType(file.extension);
        print("mimetype of the file in time of add is :- $mimeTypeStr");

        http.MediaType? contentType = mimeTypeStr != null
            ? http.MediaType.parse(mimeTypeStr)
            : null;

        if (kIsWeb) {
          print("File ${file.name} is adding now.....");

          request.files.add(
            http.MultipartFile.fromBytes(
              'files',
              file.bytes!,
              filename: file.name,
              contentType: contentType,
            ),
          );

          //print("total added file in the request in time of add is :- ${request.files.length}");
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

    if (files != null) {
      for (final file in files) {
        final mimeTypeStr = getMimeType(file.extension);
        print("mimetype of the file in time of add is :- $mimeTypeStr");

        http.MediaType? contentType = mimeTypeStr != null
            ? http.MediaType.parse(mimeTypeStr)
            : null;

        if (kIsWeb) {
          print("File ${file.name} is adding now.....");

          request.files.add(
            http.MultipartFile.fromBytes(
              'files',
              file.bytes!,
              filename: file.name,
              contentType: contentType,
            ),
          );

          //print("total added file in the request in time of add is :- ${request.files.length}");
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

  static Future<bool> removeHearing(String token, String hearingId, String userId) async {

    final response = await http.delete(
      Uri.parse("$baseUrl/$hearingId/$userId"),
      headers: authHeader(token),
    );

    if(response.statusCode != 200) {

      return false;

    }

    return true;

  }

}
