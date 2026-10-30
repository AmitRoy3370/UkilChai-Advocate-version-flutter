import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Utils/BaseURL.dart' as BASE_URL;
import '../Auth/AuthService.dart';
import 'advocate_additional_info_join_request_model.dart';

class AdvocateAdditionalInfoJoinRequestService {
  static String get _baseUrl =>
      "${BASE_URL.Urls().baseURL}advocate-additional-info-in-join-request";

  // ==================== ADD ====================
  static Future<AdvocateAdditionalInfoJoinRequest> addAdditional({
    required AdvocateAdditionalInfoJoinRequest info,
    required String userId,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse("$_baseUrl/add/$userId");

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(info.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AdvocateAdditionalInfoJoinRequest.fromJson(
            jsonDecode(response.body));
      } else {
        throw Exception("Failed to add additional info: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error adding additional info: $e");
    }
  }

  // ==================== UPDATE ====================
  static Future<AdvocateAdditionalInfoJoinRequest> updateAdditional({
    required AdvocateAdditionalInfoJoinRequest info,
    required String userId,
    required String id,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse("$_baseUrl/update/$id/$userId");

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(info.toJson()),
      );

      if (response.statusCode == 200) {
        return AdvocateAdditionalInfoJoinRequest.fromJson(
            jsonDecode(response.body));
      } else {
        throw Exception("Failed to update additional info: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating additional info: $e");
    }
  }

  // ==================== FIND BY ID ====================
  static Future<AdvocateAdditionalInfoJoinRequest> findById(String id) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/$id"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return AdvocateAdditionalInfoJoinRequest.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to find by ID: ${res.body}");
  }

  // ==================== FIND ALL ====================
  static Future<List<AdvocateAdditionalInfoJoinRequest>> findAll() async {
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
      return data
          .map((e) => AdvocateAdditionalInfoJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find all: ${res.body}");
  }

  // ==================== FIND BY ADVOCATE ID ====================
  static Future<AdvocateAdditionalInfoJoinRequest> findByAdvocateId(
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
      return AdvocateAdditionalInfoJoinRequest.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to find by advocateId: ${res.body}");
  }

  // ==================== FIND BY PERMANENT ADDRESS ====================
  static Future<List<AdvocateAdditionalInfoJoinRequest>>
      findByParmanentAdress(String parmanentAdress) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/address/$parmanentAdress"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateAdditionalInfoJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by address: ${res.body}");
  }

  // ==================== FIND BY CITY ====================
  static Future<List<AdvocateAdditionalInfoJoinRequest>> findByCityOfUpozila(
      String cityOfUpozila) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/city/$cityOfUpozila"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateAdditionalInfoJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by city: ${res.body}");
  }

  // ==================== FIND BY NID CONTAINING ====================
  static Future<List<AdvocateAdditionalInfoJoinRequest>> findByNidContaining(
      String nidNumber) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/nid/search/$nidNumber"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateAdditionalInfoJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by NID prefix: ${res.body}");
  }

  // ==================== FIND BY NID EXACT ====================
  static Future<AdvocateAdditionalInfoJoinRequest> findByNid(
      String nidNumber) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/nid/$nidNumber"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return AdvocateAdditionalInfoJoinRequest.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to find by NID: ${res.body}");
  }

  // ==================== FIND BY DATE OF BIRTH AFTER ====================
  static Future<List<AdvocateAdditionalInfoJoinRequest>>
      findByDateOfBirthAfter(String dateOfBirthIso) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/dob/after?dateOfBirth=$dateOfBirthIso"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateAdditionalInfoJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by DOB after: ${res.body}");
  }

  // ==================== FIND BY DATE OF BIRTH BEFORE ====================
  static Future<List<AdvocateAdditionalInfoJoinRequest>>
      findByDateOfBirthBefore(String dateOfBirthIso) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/dob/before?dateOfBirth=$dateOfBirthIso"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateAdditionalInfoJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by DOB before: ${res.body}");
  }

  // ==================== FIND BY WHATSAPP ====================
  static Future<AdvocateAdditionalInfoJoinRequest> findByWhatsAppNumber(
      String whatsAppNumber) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/whatsapp/$whatsAppNumber"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return AdvocateAdditionalInfoJoinRequest.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to find by WhatsApp: ${res.body}");
  }

  // ==================== DELETE ====================
  static Future<bool> deleteAdditionalInfo({
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