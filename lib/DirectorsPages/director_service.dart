// lib/DirectorsPages/director_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../DirectorsPages/director.dart';
import 'package:http_parser/http_parser.dart';
import '../DirectorsPages/director_response.dart';
import '../Utils/BaseURL.dart' as baseURL;

class DirectorService {
  final String baseUrl = baseURL.Urls().baseURL;
  String? _token;

  DirectorService({String? token}) {
    _token = token;
  }

  Future<String?> _getToken() async {
    if (_token != null && _token!.isNotEmpty) {
      return _token;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('jwt_token');
      return _token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  Map<String, String> get _headers {
    final headers = <String, String>{};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ================= ADD DIRECTOR =================
  Future<Director> addDirector({
    required Director director,
    required String userId,
    required PlatformFile? nidFile,
  }) async {
    final token = await _getToken(); 

    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('${baseUrl}directors?userId=$userId');
    final request = http.MultipartRequest('POST', uri)..headers.addAll(headers);

    request.files.add(
      http.MultipartFile.fromString(
        'director',
        jsonEncode(director.toJson()),
        contentType: MediaType('application', 'json'),
      ),
    );

    if (nidFile != null && nidFile.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'nid',
          nidFile.bytes!,
          filename: nidFile.name,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(responseBody.body);
      if (data != null) {
        final director = Director.fromJson(data);
        final directorId = director.id;
        if (directorId != null && directorId.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('directorId', directorId);
        }
        return director;
      } else {
        throw Exception('Failed to add director: Empty response');
      }
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: Check user permissions/roles or missing Bearer token');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to add director: ${response.statusCode} - ${responseBody.body}');
    }
  }

  // ================= UPDATE DIRECTOR =================
  Future<Director> updateDirector({
    required String id,
    required Director director,
    required String userId,
    required PlatformFile? nidFile,
    bool removeNid = false,
  }) async {
    final token = await _getToken();

    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('========== UPDATE DIRECTOR DEBUG ==========');
    print('ID: $id');
    print('User ID: $userId');
    print('Director Position: ${director.position}');
    print('Director NID: ${director.nid}');
    print('Remove NID: $removeNid');
    print('===========================================');

    final uri = Uri.parse('${baseUrl}directors/$id?userId=$userId');

    final request = http.MultipartRequest('PUT', uri)
      ..headers.addAll(headers);

    // ✅ Create a clean director object with all required fields
    final Map<String, dynamic> directorData = {
      'userId': userId,
      'position': director.position ?? '',
    };
    
    // ✅ Add all fields if they exist
    if (director.fullName != null && director.fullName!.isNotEmpty) {
      directorData['fullName'] = director.fullName;
    }
    if (director.fatherName != null && director.fatherName!.isNotEmpty) {
      directorData['fatherName'] = director.fatherName;
    }
    if (director.motherName != null && director.motherName!.isNotEmpty) {
      directorData['motherName'] = director.motherName;
    }
    if (director.nidNumber != null && director.nidNumber!.isNotEmpty) {
      directorData['nidNumber'] = director.nidNumber;
    }
    if (director.mobileNumber != null && director.mobileNumber!.isNotEmpty) {
      directorData['mobileNumber'] = director.mobileNumber;
    }
    if (director.email != null && director.email!.isNotEmpty) {
      directorData['email'] = director.email;
    }
    if (director.nid != null && director.nid!.isNotEmpty) {
      directorData['nid'] = director.nid;
    }
    
    // ✅ Add id if it exists
    if (id != null && id.isNotEmpty) {
      directorData['id'] = id;
    }

    final directorJson = jsonEncode(directorData);
    print('📤 Director JSON: $directorJson');
    
    request.files.add(
      http.MultipartFile.fromString(
        'director',
        directorJson,
        contentType: MediaType('application', 'json'),
      ),
    );

    // ✅ Handle NID cases
    if (removeNid) {
      print('🔄 Removing NID');
      request.files.add(
        http.MultipartFile.fromBytes(
          'nid',
          Uint8List(0),
          filename: 'remove_nid.pdf',
        ),
      );
    } else if (nidFile != null && nidFile.bytes != null && nidFile.bytes!.isNotEmpty) {
      print('🔄 Replacing NID with: ${nidFile.name}');
      request.files.add(
        http.MultipartFile.fromBytes(
          'nid',
          nidFile.bytes!,
          filename: nidFile.name,
        ),
      );
    } else {
      print('🔄 Keeping existing NID');
    }

    // ✅ Send request
    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    print('✅ Update Response Status: ${response.statusCode}');
    print('✅ Update Response Body: "${responseBody.body}"');

    if (response.statusCode == 200) {
      if (responseBody.body.isNotEmpty && responseBody.body.trim() != '') {
        try {
          final data = jsonDecode(responseBody.body);
          print('📥 Parsed response data: $data');
          
          if (data != null) {
            final updatedDirector = Director.fromJson(data);
            final directorId = updatedDirector.id;
            if (directorId != null && directorId.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('directorId', directorId);
            }
            return updatedDirector;
          }
        } catch (e) {
          print('⚠️ Error parsing response: $e');
        }
      }
      
      print('✅ Update successful, returning director with ID: $id');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('directorId', id);
      
      return Director(
        id: id,
        userId: userId,
        position: director.position ?? '',
        fullName: director.fullName,
        fatherName: director.fatherName,
        motherName: director.motherName,
        nidNumber: director.nidNumber,
        mobileNumber: director.mobileNumber,
        email: director.email,
        nid: director.nid,
      );
      
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to update director: ${response.statusCode} - ${responseBody.body}');
    }
  }

  // ================= GET ALL DIRECTORS =================
  Future<List<DirectorResponse>> getAllDirectors() async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/all');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => DirectorResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch directors: ${response.statusCode}');
    }
  }

  // ================= GET DIRECTOR BY ID =================
  Future<DirectorResponse> getDirectorById(String? id) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/$id');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DirectorResponse.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Director not found');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch director: ${response.statusCode}');
    }
  }

  // ================= GET DIRECTOR BY USER ID =================
  Future<List<DirectorResponse>> getDirectorByUserId(String? userId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/user/$userId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => DirectorResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 404) {
      throw Exception('Director not found for this user');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch director: ${response.statusCode}');
    }
  }

  // ================= GET DIRECTORS BY NID =================
  Future<List<DirectorResponse>> getDirectorsByNid(String nid) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/nid/$nid');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => DirectorResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch directors: ${response.statusCode}');
    }
  }

  // ================= GET DIRECTORS BY POSITION =================
  Future<List<DirectorResponse>> getDirectorsByPosition(String position) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/position/$position');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => DirectorResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch directors: ${response.statusCode}');
    }
  }

  // ================= SEARCH DIRECTORS BY FULL NAME =================
  Future<List<DirectorResponse>> searchDirectorsByFullName(String fullName) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/search/fullname?fullName=$fullName');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => DirectorResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search directors: ${response.statusCode}');
    }
  }

  // ================= SEARCH DIRECTORS BY FATHER NAME =================
  Future<List<DirectorResponse>> searchDirectorsByFatherName(String fatherName) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/search/fathername?fatherName=$fatherName');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => DirectorResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search directors: ${response.statusCode}');
    }
  }

  // ================= SEARCH DIRECTORS BY MOTHER NAME =================
  Future<List<DirectorResponse>> searchDirectorsByMotherName(String motherName) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/search/mothername?motherName=$motherName');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => DirectorResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search directors: ${response.statusCode}');
    }
  }

  // ================= SEARCH DIRECTORS BY MOBILE NUMBER =================
  Future<List<DirectorResponse>> searchDirectorsByMobileNumber(String mobileNumber) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/search/mobile?mobileNumber=$mobileNumber');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => DirectorResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search directors: ${response.statusCode}');
    }
  }

  // ================= SEARCH DIRECTORS BY EMAIL =================
  Future<List<DirectorResponse>> searchDirectorsByEmail(String email) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/search/email?email=$email');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => DirectorResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search directors: ${response.statusCode}');
    }
  }

  // ================= DELETE DIRECTOR =================
  Future<bool> deleteDirector(String id, String userId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}directors/$id?userId=$userId');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission to perform this action');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      return false;
    }
  }
}