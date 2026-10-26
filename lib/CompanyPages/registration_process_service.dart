// lib/CompanyPages/registration_process_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../CompanyPages/registration_process.dart';
import '../CompanyPages/registration_process_response.dart';
import '../Utils/BaseURL.dart' as baseURL;

class RegistrationProcessService {
  final String baseUrl = baseURL.Urls().baseURL;
  String? _token;

  RegistrationProcessService({String? token}) {
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

  // ==================== ADD REGISTRATION PROCESS ====================
  Future<RegistrationProcess> addRegistrationProcess({
    required RegistrationProcess process,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/add?userId=$userId');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(process.toJson()),
    );

    print('Add Registration Process Status: ${response.statusCode}');
    print('Add Registration Process Response: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RegistrationProcess.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 409) {
      throw Exception('Conflict: ${response.body}');
    } else {
      throw Exception('Failed to add registration process: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== UPDATE REGISTRATION PROCESS ====================
  Future<RegistrationProcess> updateRegistrationProcess({
    required String id,
    required RegistrationProcess process,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/update/$id?userId=$userId');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(process.toJson()),
    );

    print('Update Registration Process Status: ${response.statusCode}');
    print('Update Registration Process Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RegistrationProcess.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 409) {
      throw Exception('Conflict: ${response.body}');
    } else {
      throw Exception('Failed to update registration process: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== ADD STEP TO PROCESS ====================
  Future<RegistrationProcess> addStepToProcess({
    required String id,
    required String step,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/add-step/$id?step=$step&userId=$userId');
    final response = await http.put(uri, headers: _headers);

    print('Add Step Status: ${response.statusCode}');
    print('Add Step Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RegistrationProcess.fromJson(data);
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to add step: ${response.statusCode} - ${response.body}');
    }
  }

  // ==================== GET PROCESS BY ID ====================
  Future<RegistrationProcessResponse> getProcessById(String id) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/$id');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RegistrationProcessResponse.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Registration process not found');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch registration process: ${response.statusCode}');
    }
  }

  // ==================== GET ALL PROCESSES ====================
  Future<List<RegistrationProcessResponse>> getAllProcesses() async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/all');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => RegistrationProcessResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch registration processes: ${response.statusCode}');
    }
  }

  // ==================== GET PROCESSES BY COMPANY ID ====================
  Future<List<RegistrationProcessResponse>> getProcessesByCompanyId(String companyId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/company/$companyId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => RegistrationProcessResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch registration processes: ${response.statusCode}');
    }
  }

  // ==================== GET PROCESSES BY ADVOCATE ID ====================
  Future<List<RegistrationProcessResponse>> getProcessesByAdvocateId(String advocateId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/advocate/$advocateId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => RegistrationProcessResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch registration processes: ${response.statusCode}');
    }
  }

  // ==================== GET PROCESSES BY USER ID ====================
  Future<List<RegistrationProcessResponse>> getProcessesByUserId(String userId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/user/$userId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => RegistrationProcessResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch registration processes: ${response.statusCode}');
    }
  }

  // ==================== GET PROCESSES BY STATUS ====================
  Future<List<RegistrationProcessResponse>> getProcessesByStatus(bool status) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/status?status=$status');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => RegistrationProcessResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch registration processes: ${response.statusCode}');
    }
  }

  // ==================== GET PROCESSES BY SHARE VALUE (LTE) ====================
  Future<List<RegistrationProcessResponse>> getProcessesByShareValueLte(double shareValue) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/share-value/lte?value=$shareValue');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => RegistrationProcessResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch registration processes: ${response.statusCode}');
    }
  }

  // ==================== GET PROCESSES BY SHARE VALUE (GTE) ====================
  Future<List<RegistrationProcessResponse>> getProcessesByShareValueGte(double shareValue) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/share-value/gte?value=$shareValue');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => RegistrationProcessResponse.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch registration processes: ${response.statusCode}');
    }
  }

  // ==================== DELETE REGISTRATION PROCESS ====================
  Future<bool> deleteRegistrationProcess({
    required String id,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}registration-process/delete/$id?userId=$userId');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else if (response.statusCode == 409) {
      throw Exception('Conflict: ${response.body}');
    } else {
      return false;
    }
  }
}