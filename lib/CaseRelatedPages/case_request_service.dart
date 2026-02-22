import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './case_request.dart';

class CaseRequestService {
  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token") ?? "";
  }

  // -------------------- GET ALL --------------------
  Future<List<CaseRequest>> getAll() async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}case-request/all"),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    print(res.body);

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CaseRequest.fromJson(e))
          .toList();
    }
    throw Exception("No case request found");
  }

  // -------------------- SEARCH BY NAME --------------------
  Future<List<CaseRequest>> searchByName(String name) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}case-request/search?name=$name"),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CaseRequest.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<List<CaseRequest>> byRequestedAdvocate(String advocateId) async {
    final response = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}case-request/findByAdvocate/$advocateId",
      ),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((e) => CaseRequest.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }

  // -------------------- GET BY TYPE --------------------
  Future<List<CaseRequest>> byType(String type) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}case-request/type/$type"),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CaseRequest.fromJson(e))
          .toList();
    }
    return [];
  }

  // -------------------- GET BY USER --------------------
  Future<List<CaseRequest>> byUser(String userId) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}case-request/user/$userId"),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CaseRequest.fromJson(e))
          .toList();
    }
    return [];
  }

  // -------------------- GET BY DATE --------------------
  Future<List<CaseRequest>> afterDate(String isoDate) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}case-request/after?date=$isoDate"),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CaseRequest.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<List<CaseRequest>> beforeDate(String isoDate) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}case-request/before?date=$isoDate"),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CaseRequest.fromJson(e))
          .toList();
    }
    return [];
  }

  // -------------------- GET ONE --------------------
  Future<CaseRequest?> get(String id) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}case-request/$id"),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (res.statusCode == 200) {
      return CaseRequest.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  // -------------------- ADD CASE --------------------
  Future<bool> addCaseRequest({
    required String caseName,
    required String caseType,
    required String userId,
    List<PlatformFile>? files,
    requestedAdvocateId,
  }) async {
    final uri = Uri.parse("${BASE_URL.Urls().baseURL}case-request/add");
    final request = http.MultipartRequest("POST", uri)
      ..fields["caseName"] = caseName
      ..fields["caseType"] = caseType
      ..fields["userId"] = userId;

    if (requestedAdvocateId != null) {
      request.fields["requestedAdvocateId"] = requestedAdvocateId;
    }

    if (files != null) {
      for (final f in files) {
        if (f.bytes != null) {
          // ✅ WEB
          request.files.add(
            http.MultipartFile.fromBytes("files", f.bytes!, filename: f.name),
          );
        } else if (f.path != null) {
          // ✅ ANDROID / IOS
          request.files.add(
            await http.MultipartFile.fromPath("files", f.path!),
          );
        }
      }
    }

    request.headers["Authorization"] = "Bearer ${await _token()}";

    final response = await request.send();
    return response.statusCode == 200;
  }

  // -------------------- UPDATE CASE --------------------
  Future<bool> updateCaseRequest({
    required String caseRequestId,
    required String caseName,
    required String caseType,
    required String userId,
    required List<String> existingFiles, // 👈 OLD FILE IDS
    List<PlatformFile>? files, // 👈 NEW FILES
    String? requestedAdvocateId,
  }) async {
    final uri = Uri.parse("${BASE_URL.Urls().baseURL}case-request/update");

    final request = http.MultipartRequest("PUT", uri)
      ..fields["caseRequestId"] = caseRequestId
      ..fields["caseName"] = caseName
      ..fields["caseType"] = caseType
      ..fields["userId"] = userId
      ..fields["existingFiles"] = jsonEncode(existingFiles); // ✅ IMPORTANT

    if (files != null) {
      for (final f in files) {
        if (f.bytes != null) {
          // WEB
          request.files.add(
            http.MultipartFile.fromBytes("files", f.bytes!, filename: f.name),
          );
        } else if (f.path != null) {
          // ANDROID / IOS
          request.files.add(
            await http.MultipartFile.fromPath("files", f.path!),
          );
        }
      }
    }

    if (requestedAdvocateId != null) {
      request.fields["requestedAdvocateId"] = requestedAdvocateId;
    }

    request.headers["Authorization"] = "Bearer ${await _token()}";

    final response = await request.send();
    return response.statusCode == 200;
  }

  // -------------------- DELETE CASE --------------------
  Future<bool> deleteCase(String caseRequestId, String userId) async {
    final res = await http.delete(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}case-request/$caseRequestId/$userId",
      ),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    return res.statusCode == 200;
  }

  // -------------------- ACCEPT CASE --------------------
  Future<bool> acceptCase(String caseRequestId, String userId) async {
    final res = await http.post(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}case-request/accept/$caseRequestId/$userId",
      ),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    return res.statusCode == 200;
  }

  // -------------------- VIEW ATTACHMENT --------------------
  Future<http.Response> viewAttachment(String attachmentId) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}case-request/attachment/view/$attachmentId",
      ),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );
    return res;
  }

  // -------------------- DOWNLOAD ATTACHMENT --------------------
  Future<http.Response> downloadAttachment(String attachmentId) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}case-request/attachment/$attachmentId",
      ),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );
    return res;
  }

  Future<bool> deleteAttachment(String attachmentId) async {
    final res = await http.delete(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}case-request/attachment/$attachmentId",
      ),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    return res.statusCode == 200;
  }
}
