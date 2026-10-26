import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASE_URL;
import 'case_tracking_model.dart';

class CaseTrackingService {
  // Helper to get the token
  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? '';
  }

  // Helper for JSON headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ==================== ADD CASE TRACKING ====================
  static Future<CaseTrackingStage> addCaseTracking(
      CaseTrackingStage tracking, String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/add/$userId");
    final headers = await _getHeaders();

    final response = await http.post(url, headers: headers, body: jsonEncode(tracking.toJson()));

    if (response.statusCode == 201) {
      return CaseTrackingStage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== UPDATE CASE TRACKING ====================
  static Future<CaseTrackingStage> updateCaseTracking(
      CaseTrackingStage tracking, String id, String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/update/$id/$userId");
    final headers = await _getHeaders();

    final response = await http.put(url, headers: headers, body: jsonEncode(tracking.toJson()));

    if (response.statusCode == 200) {
      return CaseTrackingStage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== SWAP ORDER ====================
  static Future<List<CaseTrackingStage>> swapOrder(
      String trackingId1, String trackingId2) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/swap?caseTrackingId1=$trackingId1&caseTrackingId2=$trackingId2");
    final headers = await _getHeaders();

    final response = await http.put(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CaseTrackingStage.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND ALL ====================
  static Future<List<CaseTrackingStage>> findAll() async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/all");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CaseTrackingStage.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY VISIBILITY ====================
  static Future<List<CaseTrackingStage>> findByVisibility(bool visibility) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/visibility?visibility=$visibility");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CaseTrackingStage.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY CASE ID ====================
  static Future<List<CaseTrackingStage>> findByCaseId(String caseId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/case/$caseId");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CaseTrackingStage.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY CASE STAGE ====================
  static Future<List<CaseTrackingStage>> findByCaseStage(String caseStage) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/stage/$caseStage");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CaseTrackingStage.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY CASE ID AND STAGE NUMBER ====================
  static Future<CaseTrackingStage> findByCaseIdAndStageNumber(String caseId, int stageNumber) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/case/$caseId/stageNumber/$stageNumber");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return CaseTrackingStage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY CASE ID AND CASE STAGE ====================
  static Future<CaseTrackingStage> findByCaseIdAndCaseStage(String caseId, String caseStage) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/case/$caseId/stage/$caseStage");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return CaseTrackingStage.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND BY CASE ID AND STAGE NUMBER GREATER THAN ====================
  static Future<List<CaseTrackingStage>> findByCaseIdAndStageNumberGreaterThan(String caseId, int stageNumber) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/remainingLargerStage?caseId=$caseId&stageNumber=$stageNumber");
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CaseTrackingStage.fromJson(json)).toList();
    } else {
      throw Exception(_parseError(response));
    }
  }

  // ==================== FIND MY CASES ONLY ====================
  static Future<List<CaseTrackingStage>> findMyCases() async {
    // 1. Get the saved advocate ID from local storage
    final prefs = await SharedPreferences.getInstance();
    final myAdvocateId = prefs.getString('advocateId');

    if (myAdvocateId == null || myAdvocateId.isEmpty) {
      throw Exception("Advocate ID not found. Please log in again.");
    }

    // 2. Fetch all trackings from the backend
    // Using your existing findAll method
    final allTrackings = await findAll();

    // 3. Filter the trackings
    // We check if the nested trackingCase exists AND if its advocateId matches ours
    final myTrackings = allTrackings.where((tracking) {
      return tracking.trackingCase != null &&
          tracking.trackingCase!.advocateId == myAdvocateId;
    }).toList();

    // Optional: Sort them by date (closest first)
    myTrackings.sort((a, b) {
      final dateA = DateTime.tryParse(a.trackingTime ?? '') ?? DateTime(2100);
      final dateB = DateTime.tryParse(b.trackingTime ?? '') ?? DateTime(2100);
      return dateA.compareTo(dateB);
    });

    return myTrackings;
  }

  // ==================== DELETE CASE TRACKING ====================
  static Future<bool> removeCaseTracking(String id, String userId) async {
    final url = Uri.parse("${BASE_URL.Urls().baseURL}caseTracking/delete/$id/$userId");
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(_parseError(response));
    }
  }

  // Helper to extract error messages
  static String _parseError(http.Response response) {
    try {
      return response.body;
    } catch (e) {
      return "Error: ${response.statusCode}";
    }
  }
}