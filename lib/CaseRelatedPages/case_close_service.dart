import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Utils/BaseURL.dart' as BASE_URL;
import 'CaseCloseModel.dart';

class CaseCloseService {

  static String baseUrl = "${BASE_URL.Urls().baseURL}case-close";

  // ================= ADD =================
  static Future<CaseClose> addCaseClose(
      String? token,
      String? userId,
      CaseClose? caseClose) async {

    final response = await http.post(
      Uri.parse("$baseUrl/add/$userId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(caseClose?.toJson()),
    );

    if (response.statusCode == 201) {
      return CaseClose.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  // ================= UPDATE =================
  static Future<CaseClose> updateCaseClose(
      String? token,
      String? closedCaseId,
      String? userId,
      CaseClose? caseClose) async {

    final response = await http.put(
      Uri.parse("$baseUrl/update/$closedCaseId/$userId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(caseClose?.toJson()),
    );

    if (response.statusCode == 200) {
      return CaseClose.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  // ================= FIND BY ID =================
  static Future<CaseClose> findById(
      String? token,
      String? id) async {

    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return CaseClose.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

  // ================= FIND BY CASE ID =================
  static Future<CaseClose?> findByCaseId(
      String? token,
      String? caseId) async {

    final response = await http.get(
      Uri.parse("$baseUrl/case/$caseId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return CaseClose.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception(response.body);
    }
  }

  // ================= FIND ALL =================
  static Future<List<CaseClose>> findAll(String? token) async {

    final response = await http.get(
      Uri.parse("$baseUrl/all"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => CaseClose.fromJson(e)).toList();
    } else {
      throw Exception(response.body);
    }
  }

  // ================= DELETE =================
  static Future<bool> deleteCaseClose(
      String? token,
      String? closedCaseId,
      String? userId) async {

    final response = await http.delete(
      Uri.parse("$baseUrl/$closedCaseId/$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }
}
