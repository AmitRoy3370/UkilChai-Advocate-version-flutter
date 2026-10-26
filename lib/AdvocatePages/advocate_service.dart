import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'AdvocateDetailsModel.dart';
import '../Utils/AdvocateSpeciality.dart'; // Assuming you have the enum here

class AdvocateService {
  // Helper for JSON headers
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ==================== FIND BY ID ====================
  static Future<AdvocateDetailsModel> findById(String advocateId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/$advocateId");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return AdvocateDetailsModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND ALL ====================
  static Future<List<AdvocateDetailsModel>> findAll() async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/all");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateDetailsModel.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY USER ID ====================
  static Future<AdvocateDetailsModel> findByUserId(String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/findByUser/$userId");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return AdvocateDetailsModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY SPECIALITY ====================
  static Future<List<AdvocateDetailsModel>> findBySpeciality(AdvocateSpeciality speciality) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/search/speciality/${speciality.name}");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateDetailsModel.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY DISTRICT ====================
  static Future<List<AdvocateDetailsModel>> findByDistrict(String district) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/find/district/$district");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateDetailsModel.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY EXPERIENCE ====================
  static Future<List<AdvocateDetailsModel>> findByExperienceGreaterThan(int experience) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/experienceMoreThan/$experience");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateDetailsModel.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY DEGREE ====================
  static Future<List<AdvocateDetailsModel>> searchByDegree(String degree) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/search/degree/$degree");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateDetailsModel.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SEARCH BY LOCATION NAME ====================
  static Future<List<AdvocateDetailsModel>> findByLocation(String location) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/location/$location");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateDetailsModel.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY GENDER ====================
  static Future<List<AdvocateDetailsModel>> findByGender(String gender) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/findByGender/$gender");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AdvocateDetailsModel.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== ADD ADVOCATE (Multipart) ====================
  static Future<AdvocateDetailsModel> addAdvocate({
    required String usersId,
    required String userId,
    required List<AdvocateSpeciality> specialities,
    required int experience,
    required String licenseKey,
    required List<String> degrees,
    required List<String> workingExperiences,
    String? district,
    PlatformFile? cvFile,
  }) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/add/$usersId");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    // Text fields
    request.fields['userId'] = userId;
    request.fields['advocateSpeciality'] = jsonEncode(specialities.map((e) => e.name).toList());
    request.fields['experience'] = experience.toString();
    request.fields['licenseKey'] = licenseKey;
    request.fields['degrees'] = jsonEncode(degrees);
    request.fields['workingExperiences'] = jsonEncode(workingExperiences);
    if (district != null) request.fields['district'] = district;

    // File upload
    if (cvFile != null) {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          cvFile.bytes!,
          filename: cvFile.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          cvFile.path!,
        ));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AdvocateDetailsModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== UPDATE ADVOCATE (Multipart) ====================
  static Future<AdvocateDetailsModel> updateAdvocate({
    required String advocateId,
    required String usersId,
    required String userId,
    required List<AdvocateSpeciality> specialities,
    required int experience,
    required String licenseKey,
    required List<String> degrees,
    required List<String> workingExperiences,
    String? district,
    PlatformFile? cvFile,
  }) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/update/$advocateId/$usersId");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    var request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    // Text fields
    request.fields['userId'] = userId;
    request.fields['advocateSpeciality'] = jsonEncode(specialities.map((e) => e.name).toList());
    request.fields['experience'] = experience.toString();
    request.fields['licenseKey'] = licenseKey;
    request.fields['degrees'] = jsonEncode(degrees);
    request.fields['workingExperiences'] = jsonEncode(workingExperiences);
    if (district != null) request.fields['district'] = district;

    // File upload (Optional)
    if (cvFile != null) {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          cvFile.bytes!,
          filename: cvFile.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          cvFile.path!,
        ));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return AdvocateDetailsModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== DELETE ADVOCATE ====================
  static Future<bool> deleteAdvocate(String advocateId, String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}advocate/delete/$advocateId/$userId");
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(_parseError(response));
    }
  }

  // Helper method to extract error messages
  static String _parseError(http.Response response) {
    try {
      return response.body;
    } catch (e) {
      return "Error: ${response.statusCode}";
    }
  }
}