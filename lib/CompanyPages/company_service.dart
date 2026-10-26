// lib/CompanyPages/company_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../CompanyPages/company_information.dart';
import '../CompanyPages/company_response.dart';
import '../Utils/BaseURL.dart' as baseURL;

class CompanyService {
  final String baseUrl = baseURL.Urls().baseURL;
  String? _token;

  CompanyService({String? token}) {
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

  // ✅ Helper method to detect content type
  String _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // ================= CREATE COMPANY =================
  Future<CompanyInformation> createCompany({
    required CompanyInformation company,
    required String userId,
    required List<PlatformFile>? files,
  }) async {
    final token = await _getToken();

    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('========== CREATE COMPANY DEBUG ==========');
    print('User ID: $userId');
    print('Company Data: ${company.toJson()}');
    print('Files: ${files?.length ?? 0}');
    print('===========================================');

    final uri = Uri.parse('${baseUrl}company/create?userId=$userId');
    final request = http.MultipartRequest('POST', uri)..headers.addAll(headers);

    // ✅ Add company data as JSON string
    final companyJson = jsonEncode(company.toJson());
    print('📤 Company JSON: $companyJson');
    request.fields['companyData'] = companyJson;

    // ✅ Add files with proper content type
    if (files != null && files.isNotEmpty) {
      for (var file in files) {
        if (file.bytes != null && file.bytes!.isNotEmpty) {
          try {
            final contentType = _getContentType(file.name);
            print('📎 File: ${file.name}, Content-Type: $contentType');
            request.files.add(
              http.MultipartFile.fromBytes(
                'files',
                file.bytes!,
                filename: file.name,
                contentType: MediaType.parse(contentType),
              ),
            );
          } catch (e) {
            print('❌ Error adding file: $e');
            request.files.add(
              http.MultipartFile.fromBytes(
                'files',
                file.bytes!,
                filename: file.name,
              ),
            );
          }
        }
      }
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    print('Create Company Status: ${response.statusCode}');
    print('Response Body: ${responseBody.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(responseBody.body);
      if (data != null) {
        return CompanyInformation.fromJson(data);
      } else {
        throw Exception('Failed to create company: Empty response');
      }
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: Check user permissions/roles');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to create company: ${response.statusCode} - ${responseBody.body}');
    }
  }

  // ================= UPDATE COMPANY =================
  Future<CompanyInformation> updateCompany({
    required String id,
    required CompanyInformation company,
    required String userId,
    required List<PlatformFile>? files,
  }) async {
    final token = await _getToken();

    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('========== UPDATE COMPANY DEBUG ==========');
    print('ID: $id');
    print('User ID: $userId');
    print('Company Data: ${company.toJson()}');
    print('Files: ${files?.length ?? 0}');
    print('===========================================');

    final uri = Uri.parse('${baseUrl}company/update/$id?userId=$userId');
    final request = http.MultipartRequest('PUT', uri)..headers.addAll(headers);

    // ✅ Add company data as JSON string
    final companyJson = jsonEncode(company.toJson());
    print('📤 Company JSON: $companyJson');
    request.fields['companyData'] = companyJson;

    // ✅ Add files with proper content type
    if (files != null && files.isNotEmpty) {
      for (var file in files) {
        if (file.bytes != null && file.bytes!.isNotEmpty) {
          try {
            final contentType = _getContentType(file.name);
            print('📎 File: ${file.name}, Content-Type: $contentType');
            request.files.add(
              http.MultipartFile.fromBytes(
                'files',
                file.bytes!,
                filename: file.name,
                contentType: MediaType.parse(contentType),
              ),
            );
          } catch (e) {
            print('❌ Error adding file: $e');
            request.files.add(
              http.MultipartFile.fromBytes(
                'files',
                file.bytes!,
                filename: file.name,
              ),
            );
          }
        }
      }
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    print('Update Company Status: ${response.statusCode}');
    print('Updated Company Response Body: ${responseBody.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody.body);
      if (data != null) {
        return CompanyInformation.fromJson(data);
      } else {
        throw Exception('Failed to update company: Empty response');
      }
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to update company: ${response.statusCode} - ${responseBody.body}');
    }
  }

  // ================= ADD DIRECTOR TO COMPANY =================
  Future<CompanyInformation> addDirectorToCompany({
    required String companyId,
    required String directorId,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse(
      '${baseUrl}company/addDirector?id=$companyId&directorId=$directorId&userId=$userId'
    );
    final response = await http.post(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyInformation.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to add director: ${response.statusCode} - ${response.body}');
    }
  }

  // ================= ADD SHAREHOLDER TO COMPANY =================
  Future<CompanyInformation> addShareholderToCompany({
    required String companyId,
    required String shareholderId,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse(
      '${baseUrl}company/addShareholder?id=$companyId&holderId=$shareholderId&userId=$userId'
    );
    final response = await http.post(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyInformation.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to add shareholder: ${response.statusCode} - ${response.body}');
    }
  }

  // ================= GET ALL COMPANIES =================
  Future<List<CompanyResponse>> getAllCompanies() async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company/all');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('all company data :- ${data.map((e) => CompanyResponse.fromJson(e)).toList()}');
      if (data is List) {
        return data.map((e) => CompanyResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch companies: ${response.statusCode}');
    }
  }

  // ================= GET COMPANY BY ID =================
  Future<CompanyResponse> getCompanyById(String id) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company/$id');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyResponse.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Company not found');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch company: ${response.statusCode}');
    }
  }

  // ================= DELETE COMPANY =================
  Future<bool> deleteCompany(String id, String userId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company/delete/$id?userId=$userId');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      return false;
    }
  }

  // ================= SEARCH COMPANIES =================
  Future<List<CompanyResponse>> searchCompanies({
    String? companyName,
    String? type,
    String? natureOfBusiness,
    String? category,
    String? officeRegistryId,
    String? shareholderId,
    String? documentId,
    String? directorId,
    String? authorized,
    String? capital,
  }) async {
    await _getToken();

    final queryParams = <String, String>{};
    if (companyName != null) queryParams['companyName'] = companyName;
    if (type != null) queryParams['type'] = type;
    if (natureOfBusiness != null) queryParams['natureOfBuisness'] = natureOfBusiness;
    if (category != null) queryParams['category'] = category;
    if (officeRegistryId != null) queryParams['officeRegistryId'] = officeRegistryId;
    if (shareholderId != null) queryParams['shareHoldersId'] = shareholderId;
    if (documentId != null) queryParams['documentsId'] = documentId;
    if (directorId != null) queryParams['directorsId'] = directorId;
    if (authorized != null) queryParams['authorized'] = authorized;
    if (capital != null) queryParams['capital'] = capital;

    final uri = Uri.parse('${baseUrl}company/search/by-company-name')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to search companies: ${response.statusCode}');
    }
  }

// lib/CompanyPages/company_service.dart
// Add this method to the CompanyService class

// ================= GET COMPANIES BY CREATOR ID =================
Future<List<CompanyResponse>> getCompaniesByCreatorId(String userId) async {
  await _getToken();

  final uri = Uri.parse('${baseUrl}company/search/by-creator-id?creatorId=$userId');
  final response = await http.get(uri, headers: _headers);

  print('📤 Get Companies by Creator ID: $userId');
  print('📤 URL: $uri');
  print('📤 Status: ${response.statusCode}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data is List) {
      return data.map((e) => CompanyResponse.fromJson(e)).toList();
    }
    return [];
  } else if (response.statusCode == 403) {
    throw Exception('Forbidden: You do not have permission');
  } else if (response.statusCode == 401) {
    throw Exception('Unauthorized: Please login again');
  } else if (response.statusCode == 404) {
    return [];
  } else {
    throw Exception('Failed to fetch companies: ${response.statusCode}');
  }
}

}