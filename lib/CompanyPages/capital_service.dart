// lib/CompanyPages/capital_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../CompanyPages/capital.dart';
import '../Utils/BaseURL.dart' as baseURL;

class CapitalService {
  final String baseUrl = baseURL.Urls().baseURL;
  String? _token;

  CapitalService({String? token}) {
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

  // ==================== ADD CAPITAL ====================
  Future<Capital> addCapital({
    required Capital capital,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/add?userId=$userId');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(capital.toJson()),
    );

    print('Add Capital Status: ${response.statusCode}');
    print('Add Capital Response: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Capital.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to add capital: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== UPDATE CAPITAL ====================
  Future<Capital> updateCapital({
    required String id,
    required Capital capital,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/update/$id?userId=$userId');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(capital.toJson()),
    );

    print('Update Capital Status: ${response.statusCode}');
    print('Update Capital Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Capital.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to update capital: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== GET CAPITAL BY ID ====================
  Future<Capital> getCapitalById(String id) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/$id');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Capital.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Capital not found');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch capital: ${response.statusCode}');
    }
  }

  // ==================== GET ALL CAPITALS ====================
  Future<List<Capital>> getAllCapitals() async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/all');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Capital.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch capitals: ${response.statusCode}');
    }
  }

  // ==================== GET CAPITALS BY COMPANY ID ====================
  Future<List<Capital>> getCapitalsByCompanyId(String companyId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/company/$companyId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Capital.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch capitals: ${response.statusCode}');
    }
  }

  // ==================== FILTER: AUTHORIZED CAPITAL <= (LTE) ====================
  Future<List<Capital>> findByAuthorizedCapitalLte(double value) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/filter/authorized-capital/lte?value=$value');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Capital.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to filter capitals: ${response.statusCode}');
    }
  }

  // ==================== FILTER: AUTHORIZED CAPITAL >= (GTE) ====================
  Future<List<Capital>> findByAuthorizedCapitalGte(double value) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/filter/authorized-capital/gte?value=$value');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Capital.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to filter capitals: ${response.statusCode}');
    }
  }

  // ==================== FILTER: TOTAL SHARE <= (LTE) ====================
  Future<List<Capital>> findByTotalShareLte(int value) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/filter/total-share/lte?value=$value');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Capital.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to filter capitals: ${response.statusCode}');
    }
  }

  // ==================== FILTER: TOTAL SHARE >= (GTE) ====================
  Future<List<Capital>> findByTotalShareGte(int value) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/filter/total-share/gte?value=$value');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Capital.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to filter capitals: ${response.statusCode}');
    }
  }

  // ==================== FILTER: NUMBER OF SHARE <= (LTE) ====================
  Future<List<Capital>> findByNumberOfShareLte(int value) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/filter/number-of-share/lte?value=$value');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Capital.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to filter capitals: ${response.statusCode}');
    }
  }

  // ==================== FILTER: NUMBER OF SHARE >= (GTE) ====================
  Future<List<Capital>> findByNumberOfShareGte(int value) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/filter/number-of-share/gte?value=$value');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Capital.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to filter capitals: ${response.statusCode}');
    }
  }

  // ==================== FILTER: SHARE VALUE <= (LTE) ====================
  Future<List<Capital>> findByShareValueLte(double value) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/filter/share-value/lte?value=$value');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Capital.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to filter capitals: ${response.statusCode}');
    }
  }

  // ==================== FILTER: SHARE VALUE >= (GTE) ====================
  Future<List<Capital>> findByShareValueGte(double value) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/filter/share-value/gte?value=$value');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Capital.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to filter capitals: ${response.statusCode}');
    }
  }

  // ==================== DELETE CAPITAL ====================
  Future<bool> deleteCapital({
    required String id,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}capitals/delete/$id?userId=$userId');
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