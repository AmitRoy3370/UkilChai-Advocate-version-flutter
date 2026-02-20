import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASE_URL;

import 'AppealHearingModel.dart';

class AppealHearingService {
  static String baseUrl =
      "${BASE_URL.Urls().baseURL.replaceFirst('/api/', '/')}appealHearing";

  // ================= AUTH HEADER =================
  static Map<String, String> authHeader(String token) {
    return {"Authorization": "Bearer $token"};
  }

  // ================= ADD APPEAL =================
  static Future<http.Response> addAppeal({
    required String token,
    required String userId,
    required String hearingId,
    required String reason,
    DateTime? appealHearingTime,
  }) async {
    final uri = Uri.parse("$baseUrl/add/$userId");
    final request = http.MultipartRequest("POST", uri);

    request.headers.addAll(authHeader(token));
    request.fields['hearingId'] = hearingId;
    request.fields['reason'] = reason;

    if (appealHearingTime != null) {
      request.fields['appealHearingTime'] = appealHearingTime
          .toUtc()
          .toIso8601String();
    }

    final response = await request.send();
    return http.Response.fromStream(response);
  }

  // ================= UPDATE APPEAL =================
  static Future<http.Response> updateAppeal({
    required String token,
    required String appealId,
    required String userId,
    required String hearingId,
    required String reason,
    DateTime? appealHearingTime,
  }) async {
    final uri = Uri.parse("$baseUrl/update/$appealId/$userId");
    final request = http.MultipartRequest("PUT", uri);

    request.headers.addAll(authHeader(token));
    request.fields['hearingId'] = hearingId;
    request.fields['reason'] = reason;

    if (appealHearingTime != null) {
      request.fields['appealHearingTime'] = appealHearingTime
          .toUtc()
          .toIso8601String();
    }

    final response = await request.send();
    return http.Response.fromStream(response);
  }

  // ================= BY HEARING =================
  static Future<AppealHearing?> getByHearing(
    String token,
    String hearingId,
  ) async {

    print("appeal for hearing :- $hearingId with token :- $token");

    final response = await http.get(
      Uri.parse("$baseUrl/hearing/$hearingId"),
      headers: authHeader(token),
    );

    print("response status for appeal hearing :- ${response.statusCode}");

    if(response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppealHearing.fromJson(data);
    } else {

      return null;

    }

  }

  // ================= BY REASON =================
  static Future<List<AppealHearing>> getByReason(
    String token,
    String reason,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/reason/$reason"),
      headers: authHeader(token),
    );

    final List data = jsonDecode(response.body);
    return data.map((e) => AppealHearing.fromJson(e)).toList();
  }

  // ================= BEFORE DATE =================
  static Future<List<AppealHearing>> getBeforeDate(
    String token,
    DateTime date,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/before?date=${date.toUtc().toIso8601String()}"),
      headers: authHeader(token),
    );

    final List data = jsonDecode(response.body);
    return data.map((e) => AppealHearing.fromJson(e)).toList();
  }

  // ================= AFTER DATE =================
  static Future<List<AppealHearing>> getAfterDate(
    String token,
    DateTime date,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/after?date=${date.toUtc().toIso8601String()}"),
      headers: authHeader(token),
    );

    final List data = jsonDecode(response.body);
    return data.map((e) => AppealHearing.fromJson(e)).toList();
  }

  // ================= ALL =================
  static Future<List<AppealHearing>> getAll(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/all"),
      headers: authHeader(token),
    );

    final List data = jsonDecode(response.body);
    return data.map((e) => AppealHearing.fromJson(e)).toList();
  }

  // ================= BY ID =================
  static Future<AppealHearing> getById(String token, String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$id"),
      headers: authHeader(token),
    );

    return AppealHearing.fromJson(jsonDecode(response.body));
  }

  // ================= DELETE =================
  static Future<http.Response> deleteAppeal({
    required String token,
    required String appealId,
    required String userId,
  }) async {
    return await http.delete(
      Uri.parse("$baseUrl/$appealId/$userId"),
      headers: authHeader(token),
    );
  }
}
