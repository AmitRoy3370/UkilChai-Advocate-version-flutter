// lib/CompanyPages/company_contact_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../CompanyPages/company_contact.dart';
import '../Utils/BaseURL.dart' as baseURL;

class CompanyContactService {
  final String baseUrl = baseURL.Urls().baseURL;
  String? _token;

  CompanyContactService({String? token}) {
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
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ==================== ADD COMPANY CONTACT ====================
  Future<CompanyContact> addCompanyContact({
    required CompanyContact contact,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/add?userId=$userId');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(contact.toJson()),
    );

    print('Add Company Contact Status: ${response.statusCode}');
    print('Add Company Contact Response: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyContact.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to add company contact: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== UPDATE COMPANY CONTACT ====================
  Future<CompanyContact> updateCompanyContact({
    required String id,
    required CompanyContact contact,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/update/$id?userId=$userId');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(contact.toJson()),
    );

    print('Update Company Contact Status: ${response.statusCode}');
    print('Update Company Contact Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyContact.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to update company contact: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== GET ALL COMPANY CONTACTS ====================
  Future<List<CompanyContact>> getAllCompanyContacts() async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/all');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyContact.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch company contacts: ${response.statusCode}');
    }
  }

  // ==================== GET COMPANY CONTACT BY ID ====================
  Future<CompanyContact> getCompanyContactById(String id) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/$id');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyContact.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Company contact not found');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch company contact: ${response.statusCode}');
    }
  }

  // ==================== GET CONTACTS BY COMPANY ID ====================
  Future<List<CompanyContact>> getContactsByCompanyId(String companyId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/company/$companyId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyContact.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch company contacts: ${response.statusCode}');
    }
  }

  // ==================== SEARCH CONTACTS BY NAME ====================
  Future<List<CompanyContact>> searchContactsByName(String name) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/search/name?name=$name');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyContact.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to search company contacts: ${response.statusCode}');
    }
  }

  // ==================== SEARCH CONTACTS BY MOBILE ====================
  Future<List<CompanyContact>> searchContactsByMobile(String mobile) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/search/mobile?mobile=$mobile');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyContact.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to search company contacts: ${response.statusCode}');
    }
  }

  // ==================== SEARCH CONTACTS BY EMAIL ====================
  Future<List<CompanyContact>> searchContactsByEmail(String email) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/search/email?email=$email');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyContact.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to search company contacts: ${response.statusCode}');
    }
  }

  // ==================== SEARCH CONTACTS BY "HOW DID HEAR" ====================
  Future<List<CompanyContact>> searchContactsByHowDidHear(String query) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/search/how-did-hear?query=$query');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyContact.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to search company contacts: ${response.statusCode}');
    }
  }

  // ==================== SEARCH CONTACTS BY MESSAGE ====================
  Future<List<CompanyContact>> searchContactsByMessage(String message) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/search/message?message=$message');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CompanyContact.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to search company contacts: ${response.statusCode}');
    }
  }

  // ==================== DELETE COMPANY CONTACT ====================
  Future<bool> deleteCompanyContact({
    required String id,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}company-contacts/delete/$id?userId=$userId');
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