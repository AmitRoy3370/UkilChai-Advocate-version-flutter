import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import '../Auth/AuthService.dart';
import 'advocate_documents_join_request_model.dart';

class AdvocateDocumentsJoinRequestService {
  static String get _baseUrl =>
      "${BASE_URL.Urls().baseURL}advocate-documents-in-join-request";

  // ==================== ADD ====================
  static Future<AdvocateDocumentsJoinRequest> addDocuments({
    required String advocateId,
    required List<PlatformFile> files,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse("$_baseUrl/add/$advocateId");

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Add files
      for (var file in files) {
        if (kIsWeb) {
          if (file.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'files',
                file.bytes!,
                filename: file.name,
              ),
            );
          }
        } else {
          if (file.path != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'files',
                file.path!,
                filename: file.name,
              ),
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AdvocateDocumentsJoinRequest.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to add documents: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error adding documents: $e");
    }
  }

  // ==================== UPDATE ====================
  static Future<AdvocateDocumentsJoinRequest> updateDocuments({
    required String id,
    required String userId,
    required AdvocateDocumentsJoinRequest documents,
    List<PlatformFile>? newFiles,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse("$_baseUrl/update/$id/$userId");

      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Add the JSON part
      request.files.add(
        http.MultipartFile.fromString(
          'documents',
          jsonEncode(documents.toJson()),
          contentType: MediaType('application', 'json'),
        ),
      );

      // Add new files if any
      if (newFiles != null && newFiles.isNotEmpty) {
        for (var file in newFiles) {
          if (kIsWeb) {
            if (file.bytes != null) {
              request.files.add(
                http.MultipartFile.fromBytes(
                  'files',
                  file.bytes!,
                  filename: file.name,
                ),
              );
            }
          } else {
            if (file.path != null) {
              request.files.add(
                await http.MultipartFile.fromPath(
                  'files',
                  file.path!,
                  filename: file.name,
                ),
              );
            }
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return AdvocateDocumentsJoinRequest.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to update documents: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating documents: $e");
    }
  }

  // ==================== FIND BY ID ====================
  static Future<AdvocateDocumentsJoinRequest> findById(String id) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/$id"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return AdvocateDocumentsJoinRequest.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to find by ID: ${res.body}");
  }

  // ==================== FIND ALL ====================
  static Future<List<AdvocateDocumentsJoinRequest>> findAll() async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/all"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => AdvocateDocumentsJoinRequest.fromJson(e)).toList();
    }
    throw Exception("Failed to find all: ${res.body}");
  }

  // ==================== FIND BY ADVOCATE ID ====================
  static Future<AdvocateDocumentsJoinRequest> findByAdvocateId(
      String advocateId) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/advocate/$advocateId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return AdvocateDocumentsJoinRequest.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to find by advocateId: ${res.body}");
  }

  // ==================== FIND BY ATTACHMENT ID ====================
  static Future<List<AdvocateDocumentsJoinRequest>> findByAttachment(
      String attachmentId) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/attachment/$attachmentId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => AdvocateDocumentsJoinRequest.fromJson(e)).toList();
    }
    throw Exception("Failed to find by attachment: ${res.body}");
  }

  // ==================== DELETE ====================
  static Future<bool> deleteDocuments({
    required String id,
    required String userId,
  }) async {
    final token = await AuthService.getToken();
    final res = await http.delete(
      Uri.parse("$_baseUrl/delete/$id/$userId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return res.statusCode == 200;
  }
}