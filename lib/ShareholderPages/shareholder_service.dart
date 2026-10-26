// lib/ShareholderPages/shareholder_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../ShareholderPages/shareholder.dart';
import '../ShareholderPages/shareholder_response.dart';
import '../Utils/BaseURL.dart' as baseURL;

class ShareholderService {
  final String baseUrl = baseURL.Urls().baseURL;
  String? _token;

  ShareholderService({String? token}) {
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

  // ================= ADD SHAREHOLDER =================
  Future<Shareholder> addShareholder({
    required Shareholder shareholder,
    required String userId,
    required PlatformFile? nidFile,
    required PlatformFile? tinFile,
  }) async {
    final token = await _getToken();

    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('========== ADD SHAREHOLDER DEBUG ==========');
    print('User ID: $userId');
    print('Shareholder Data: ${shareholder.toJson()}');
    print('NID File: ${nidFile?.name ?? 'null'}');
    print('TIN File: ${tinFile?.name ?? 'null'}');
    print('===========================================');

    final uri = Uri.parse('${baseUrl}shareholders?userId=$userId');
    final request = http.MultipartRequest('POST', uri)..headers.addAll(headers);

    // Add shareholder as JSON
    final shareholderJson = jsonEncode(shareholder.toJson());
    print('📤 Shareholder JSON: $shareholderJson');
    
    request.files.add(
      http.MultipartFile.fromString(
        'shareholder',
        shareholderJson,
        contentType: MediaType('application', 'json'),
      ),
    );

    // Add NID file with proper content type
    if (nidFile != null && nidFile.bytes != null && nidFile.bytes!.isNotEmpty) {
      try {
        final contentType = _getContentType(nidFile.name);
        print('📎 NID File: ${nidFile.name}, Content-Type: $contentType');
        request.files.add(
          http.MultipartFile.fromBytes(
            'nid',
            nidFile.bytes!,
            filename: nidFile.name,
            contentType: MediaType.parse(contentType),
          ),
        );
      } catch (e) {
        print('❌ Error adding NID file: $e');
        request.files.add(
          http.MultipartFile.fromBytes(
            'nid',
            nidFile.bytes!,
            filename: nidFile.name,
          ),
        );
      }
    }

    // Add TIN file with proper content type
    if (tinFile != null && tinFile.bytes != null && tinFile.bytes!.isNotEmpty) {
      try {
        final contentType = _getContentType(tinFile.name);
        print('📎 TIN File: ${tinFile.name}, Content-Type: $contentType');
        request.files.add(
          http.MultipartFile.fromBytes(
            'tin',
            tinFile.bytes!,
            filename: tinFile.name,
            contentType: MediaType.parse(contentType),
          ),
        );
      } catch (e) {
        print('❌ Error adding TIN file: $e');
        request.files.add(
          http.MultipartFile.fromBytes(
            'tin',
            tinFile.bytes!,
            filename: tinFile.name,
          ),
        );
      }
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    print('Add Shareholder Status: ${response.statusCode}');
    print('Response Body: ${responseBody.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(responseBody.body);
      if (data != null) {
        final shareholder = Shareholder.fromJson(data);
        final shareholderId = shareholder.id;
        if (shareholderId != null && shareholderId.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('shareholderId', shareholderId);
          await prefs.setString('shareHolderId', shareholderId);
          print('✅ Shareholder ID saved: $shareholderId');
        }
        return shareholder;
      } else {
        throw Exception('Failed to add shareholder: Empty response');
      }
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: Check user permissions/roles');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to add shareholder: ${response.statusCode} - ${responseBody.body}');
    }
  }

  // ================= UPDATE SHAREHOLDER =================
  Future<Shareholder> updateShareholder({
    required String id,
    required Shareholder shareholder,
    required String userId,
    required PlatformFile? nidFile,
    required PlatformFile? tinFile,
    bool removeNid = false,
    bool removeTin = false,
  }) async {
    final token = await _getToken();

    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('========== UPDATE SHAREHOLDER DEBUG ==========');
    print('ID: $id');
    print('User ID: $userId');
    print('Shareholder Data: ${shareholder.toJson()}');
    print('NID File: ${nidFile?.name ?? 'null'}');
    print('TIN File: ${tinFile?.name ?? 'null'}');
    print('Remove NID: $removeNid');
    print('Remove TIN: $removeTin');
    print('===========================================');

    final uri = Uri.parse('${baseUrl}shareholders/$id?userId=$userId');
    print('requested url for update shareholder :- $uri');
    final request = http.MultipartRequest('PUT', uri)..headers.addAll(headers);

    // ✅ Create clean shareholder data
    final Map<String, dynamic> shareholderData = {
      'userId': userId,
    };
    
    // ✅ Add nid if it exists and not being removed
    if (shareholder.nid != null && shareholder.nid!.isNotEmpty && !removeNid) {
      shareholderData['nid'] = shareholder.nid;
    }
    
    // ✅ Add tin if it exists and not being removed
    if (shareholder.tin != null && shareholder.tin!.isNotEmpty && !removeTin) {
      shareholderData['tin'] = shareholder.tin;
    }
    
    // ✅ Add id if it exists
    if (id != null && id.isNotEmpty) {
      shareholderData['id'] = id;
    }

    shareholderData['fullName'] = shareholder.fullName ?? "Un-Named";

    if (shareholder.sharePercentage != null && shareholder.sharePercentage!.isNotEmpty) {
      shareholderData['sharePercentage'] = shareholder.sharePercentage;
      print('📊 Adding sharePercentage: ${shareholder.sharePercentage}');
    } else {
      // Even if empty, send an empty map to ensure the field exists
      shareholderData['sharePercentage'] = {};
      print('📊 Sending empty sharePercentage');
    }

    final shareholderJson = jsonEncode(shareholderData);
    print('📤 Shareholder JSON: $shareholderJson');
    
    request.files.add(
      http.MultipartFile.fromString(
        'shareholder',
        shareholderJson,
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
      try {
        final contentType = _getContentType(nidFile.name);
        print('📎 New NID File: ${nidFile.name}, Content-Type: $contentType');
        request.files.add(
          http.MultipartFile.fromBytes(
            'nid',
            nidFile.bytes!,
            filename: nidFile.name,
            contentType: MediaType.parse(contentType),
          ),
        );
      } catch (e) {
        print('❌ Error adding NID file: $e');
        request.files.add(
          http.MultipartFile.fromBytes(
            'nid',
            nidFile.bytes!,
            filename: nidFile.name,
          ),
        );
      }
    } else {
      print('🔄 Keeping existing NID');
    }

    // ✅ Handle TIN cases
    if (removeTin) {
      print('🔄 Removing TIN');
      request.files.add(
        http.MultipartFile.fromBytes(
          'tin',
          Uint8List(0),
          filename: 'remove_tin.pdf',
        ),
      );
    } else if (tinFile != null && tinFile.bytes != null && tinFile.bytes!.isNotEmpty) {
      try {
        final contentType = _getContentType(tinFile.name);
        print('📎 New TIN File: ${tinFile.name}, Content-Type: $contentType');
        request.files.add(
          http.MultipartFile.fromBytes(
            'tin',
            tinFile.bytes!,
            filename: tinFile.name,
            contentType: MediaType.parse(contentType),
          ),
        );
      } catch (e) {
        print('❌ Error adding TIN file: $e');
        request.files.add(
          http.MultipartFile.fromBytes(
            'tin',
            tinFile.bytes!,
            filename: tinFile.name,
          ),
        );
      }
    } else {
      print('🔄 Keeping existing TIN');
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    print('✅ Update Shareholder Status: ${response.statusCode}');
    print('✅ Response Body: "${responseBody.body}"');

    if (response.statusCode == 200) {
      if (responseBody.body.isNotEmpty && responseBody.body.trim() != '') {
        try {
          final data = jsonDecode(responseBody.body);
          print('📥 Parsed response data: $data');
          
          if (data != null) {
            final updatedShareholder = Shareholder.fromJson(data);
            final shareholderId = updatedShareholder.id;
            if (shareholderId != null && shareholderId.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('shareholderId', shareholderId);
              await prefs.setString('shareHolderId', shareholderId);
              print('✅ Shareholder ID saved: $shareholderId');
            }
            return updatedShareholder;
          }
        } catch (e) {
          print('⚠️ Error parsing response: $e');
        }
      }
      
      // ✅ If we reach here, either response was empty or parsing failed
      print('✅ Update successful, returning shareholder with ID: $id');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shareholderId', id);
      await prefs.setString('shareHolderId', id);
      
      return Shareholder(
        id: id,
        userId: userId,
        nid: removeNid ? null : (shareholder.nid ?? ''),
        tin: removeTin ? null : (shareholder.tin ?? ''),
        sharePercentage: shareholder.sharePercentage ?? {},
      );
      
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to update shareholder: ${response.statusCode} - ${responseBody.body}');
    }
  }

  // ================= SHARE PROFIT =================
  Future<Shareholder> shareProfit({
    required String companyId,
    required double percentage,
    required String holderId,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse(
      '${baseUrl}shareholders/share-profit?companyId=$companyId&percentage=$percentage&holderId=$holderId&userId=$userId'
    );
    final response = await http.post(uri, headers: _headers);

    print('Share Profit Status: ${response.statusCode}');
    print('Share Profit Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Shareholder.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to share profit: ${response.statusCode} - ${response.body}');
    }
  }

  // ================= GET ALL SHAREHOLDERS =================
  Future<List<ShareholderResponse>> getAllShareholders() async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ShareholderResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch shareholders: ${response.statusCode}');
    }
  }

  // ================= GET SHAREHOLDER BY ID =================
  Future<ShareholderResponse> getShareholderById(String? id) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders/$id');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ShareholderResponse.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Shareholder not found');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch shareholder: ${response.statusCode}');
    }
  }

  // ================= GET SHAREHOLDERS BY FULL NAME =================
  Future<List<ShareholderResponse>> getShareholdersByFullName(String fullName) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders/fullName/$fullName');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ShareholderResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to fetch shareholders: ${response.statusCode}');
    }
  }

  // ================= GET SHAREHOLDER BY USER ID =================
  Future<List<ShareholderResponse>> getShareholderByUserId(String? userId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders/user/$userId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ShareholderResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 404) {
      throw Exception('Shareholder not found for this user');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch shareholder: ${response.statusCode}');
    }
  }

  // ================= GET SHAREHOLDERS BY NID =================
  Future<List<ShareholderResponse>> getShareholdersByNid(String nid) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders/nid/$nid');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ShareholderResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to fetch shareholders: ${response.statusCode}');
    }
  }

  // ================= GET SHAREHOLDERS BY TIN =================
  Future<List<ShareholderResponse>> getShareholdersByTin(String tin) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders/tin/$tin');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ShareholderResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to fetch shareholders: ${response.statusCode}');
    }
  }

  // ================= SEARCH BY COMPANY ID =================
  Future<List<ShareholderResponse>> searchByCompanyId(String companyId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders/search/company/$companyId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ShareholderResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search shareholders: ${response.statusCode}');
    }
  }

  // ================= SEARCH BY COMPANY ID AND EXACT PERCENTAGE =================
  Future<List<ShareholderResponse>> searchByCompanyIdAndPercentage({
    required String companyId,
    required double percentage,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders/search/company/$companyId/percentage/$percentage');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ShareholderResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search shareholders: ${response.statusCode}');
    }
  }

  // ================= SEARCH BY COMPANY ID AND PERCENTAGE GTE =================
  Future<List<ShareholderResponse>> searchByCompanyIdAndPercentageGte({
    required String companyId,
    required double percentage,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders/search/company/$companyId/gte/$percentage');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ShareholderResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search shareholders: ${response.statusCode}');
    }
  }

  // ================= SEARCH BY COMPANY ID AND PERCENTAGE LTE =================
  Future<List<ShareholderResponse>> searchByCompanyIdAndPercentageLte({
    required String companyId,
    required double percentage,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders/search/company/$companyId/lte/$percentage');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ShareholderResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search shareholders: ${response.statusCode}');
    }
  }

  // ================= SEARCH BY COMPANY ID AND PERCENTAGE BETWEEN =================
  Future<List<ShareholderResponse>> searchByCompanyIdAndPercentageBetween({
    required String companyId,
    required double minPercentage,
    required double maxPercentage,
  }) async {
    await _getToken();

    final uri = Uri.parse(
      '${baseUrl}shareholders/search/company/$companyId/between?minPercentage=$minPercentage&maxPercentage=$maxPercentage'
    );
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => ShareholderResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to search shareholders: ${response.statusCode}');
    }
  }

  // ================= DELETE SHAREHOLDER =================
  Future<bool> deleteShareholder(String id, String userId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}shareholders/$id?userId=$userId');
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
}