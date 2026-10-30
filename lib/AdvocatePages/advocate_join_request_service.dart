import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import '../Auth/AuthService.dart';
import 'Models/advocate_join_request_dto_model.dart';

class AdvocateJoinRequestService {
  static String get _baseUrl =>
      "${BASE_URL.Urls().baseURL}advocateJoinRequest";

  // ==================== ADD REQUEST ====================
  static Future<Map<String, dynamic>> addAdvocateRequest({
    required String userId,
    required List<String> advocateSpeciality,
    required int experience,
    required String licenseKey,
    required List<String> degrees,
    required List<String> workingExperiences,
    String? district,
    PlatformFile? file,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse(_baseUrl);

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['userId'] = userId;
      request.fields['advocateSpeciality'] = jsonEncode(advocateSpeciality);
      request.fields['experience'] = experience.toString();
      request.fields['licenseKey'] = licenseKey;
      request.fields['degrees'] = jsonEncode(degrees);
      request.fields['workingExperiences'] = jsonEncode(workingExperiences);

      if (district != null && district.isNotEmpty) {
        request.fields['district'] = district;
      }

      if (file != null) {
        if (kIsWeb) {
          if (file.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
          }
        } else {
          if (file.path != null) {
            request.files.add(await http.MultipartFile.fromPath('file', file.path!, filename: file.name));
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to add request: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error adding request: $e");
    }
  }

  // ==================== UPDATE REQUEST ====================
  static Future<Map<String, dynamic>> updateAdvocateRequest({
    required String advocateId,
    required String userId,
    required List<String> advocateSpeciality,
    required int experience,
    required String licenseKey,
    required List<String> degrees,
    required List<String> workingExperiences,
    String? district,
    PlatformFile? file,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse("$_baseUrl/$advocateId");

      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['userId'] = userId;
      request.fields['advocateSpeciality'] = jsonEncode(advocateSpeciality);
      request.fields['experience'] = experience.toString();
      request.fields['licenseKey'] = licenseKey;
      request.fields['degrees'] = jsonEncode(degrees);
      request.fields['workingExperiences'] = jsonEncode(workingExperiences);

      if (district != null && district.isNotEmpty) {
        request.fields['district'] = district;
      }

      if (file != null) {
        if (kIsWeb) {
          if (file.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
          }
        } else {
          if (file.path != null) {
            request.files.add(await http.MultipartFile.fromPath('file', file.path!, filename: file.name));
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to update request: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating request: $e");
    }
  }

  // ==================== HANDLE JOIN REQUEST (Approve) ====================
  static Future<Map<String, dynamic>> handleJoinRequest({
    required String userId,
    required String advocateJoinRequestId,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("$_baseUrl/handleJoinRequest?userId=$userId&advocateJoinRequestId=$advocateJoinRequestId");

    final response = await http.put(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to approve request: ${response.body}");
  }

  // ==================== DELETE REQUEST ====================
  static Future<bool> deleteRequest({
    required String advocateId,
    required String userId,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("$_baseUrl/delete/$advocateId?userId=$userId");

    final response = await http.delete(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return true;
    }
    throw Exception("Failed to delete request: ${response.body}");
  }

  // ==================== GET ALL REQUESTS ====================
  static Future<List<AdvocateJoinRequestDTO>> getAllRequests() async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("$_baseUrl/all");

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AdvocateJoinRequestDTO.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch all requests: ${response.body}");
  }

  // ==================== FIND BY USER ID ====================
  static Future<AdvocateJoinRequestDTO> findByUserId(String userId) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("$_baseUrl/user/$userId");

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return AdvocateJoinRequestDTO.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to find by userId: ${response.body}");
  }

  // ==================== FIND BY SPECIALITY ====================
  static Future<List<AdvocateJoinRequestDTO>> findBySpeciality(String speciality) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("$_baseUrl/speciality/$speciality");

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AdvocateJoinRequestDTO.fromJson(e)).toList();
    }
    throw Exception("Failed to find by speciality: ${response.body}");
  }

  // ==================== FIND BY LICENSE ====================
  static Future<AdvocateJoinRequestDTO> findByLicense(String licenseKey) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("$_baseUrl/license/$licenseKey");

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return AdvocateJoinRequestDTO.fromJson(jsonDecode(response.body));
    }
    throw Exception("Failed to find by license: ${response.body}");
  }

  // ==================== FIND BY EXPERIENCE GREATER THAN ====================
  static Future<List<AdvocateJoinRequestDTO>> findByExperience(int year) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("$_baseUrl/experience/$year");

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AdvocateJoinRequestDTO.fromJson(e)).toList();
    }
    throw Exception("Failed to find by experience: ${response.body}");
  }

  // ==================== FIND BY DEGREE ====================
  static Future<List<AdvocateJoinRequestDTO>> findByDegree(String degree) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("$_baseUrl/degree/$degree");

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AdvocateJoinRequestDTO.fromJson(e)).toList();
    }
    throw Exception("Failed to find by degree: ${response.body}");
  }

  // ==================== FIND BY WORKING EXPERIENCE ====================
  static Future<List<AdvocateJoinRequestDTO>> findByWorkExp(String experience) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("$_baseUrl/work/$experience");

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AdvocateJoinRequestDTO.fromJson(e)).toList();
    }
    throw Exception("Failed to find by work experience: ${response.body}");
  }
}