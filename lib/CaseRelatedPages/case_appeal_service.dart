import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/AppealCaseModel.dart';
import 'ApiClient.dart';

class CaseAppealService {
  final String token;

  CaseAppealService(this.token);

  Dio get _dio => ApiClient.dio(token);

  // ================= ADD =================
  Future<AppealCase> addAppeal({
    required String userId,
    required String caseId,
    required String reason,
  }) async {
    final formData = FormData.fromMap({"caseId": caseId, "reason": reason});

    final response = await _dio.post("/appealCase/add/$userId", data: formData);

    return AppealCase.fromJson(response.data);
  }

  // ================= UPDATE =================
  Future<AppealCase> updateAppeal({
    required String appealId,
    required String userId,
    required String caseId,
    required String reason,
  }) async {
    final formData = FormData.fromMap({"caseId": caseId, "reason": reason});

    final response = await _dio.put(
      "appealCase/update/$appealId/$userId",
      data: formData,
    );

    return AppealCase.fromJson(response.data);
  }

  // ================= BY CASE ID =================
  Future<AppealCase?> getByCaseId(String caseId) async {
    final response = await _dio.get("appealCase/case/$caseId");

    if (response.statusCode == 200) {
      return AppealCase.fromJson(response.data);
    }
    return null;
  }

  // ================= SEARCH BY REASON =================
  Future<List<AppealCase>> searchByReason(String reason) async {
    final response = await _dio.get(
      "appealCase/search",
      queryParameters: {"reason": reason},
    );

    return (response.data as List).map((e) => AppealCase.fromJson(e)).toList();
  }

  // ================= DATE AFTER =================
  Future<List<AppealCase>> afterDate(DateTime date) async {
    final response = await _dio.get(
      "appealCase/afterDate",
      queryParameters: {"date": date.toIso8601String()},
    );

    return (response.data as List).map((e) => AppealCase.fromJson(e)).toList();
  }

  // ================= DATE BEFORE =================
  Future<List<AppealCase>> beforeDate(DateTime date) async {
    final response = await _dio.get(
      "appealCase/beforeDate",
      queryParameters: {"date": date.toIso8601String()},
    );

    return (response.data as List).map((e) => AppealCase.fromJson(e)).toList();
  }

  // ================= GET ALL =================
  Future<List<AppealCase>> getAll() async {
    final response = await _dio.get("appealCase/showAll");

    return (response.data as List).map((e) => AppealCase.fromJson(e)).toList();
  }

  // ================= GET BY ID =================
  Future<AppealCase> getById(String id) async {
    final response = await _dio.get("appealCase/id/$id");
    return AppealCase.fromJson(response.data);
  }

  // ================= DELETE =================
  Future<void> deleteAppeal({
    required String id,
    required String userId,
  }) async {
    await _dio.delete("appealCase/delete/$id/$userId");
  }
}
