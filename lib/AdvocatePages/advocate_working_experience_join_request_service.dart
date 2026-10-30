import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Utils/BaseURL.dart' as BASE_URL;
import '../Auth/AuthService.dart';
import 'advocate_working_experience_join_request_model.dart';

class AdvocateWorkingExperienceJoinRequestService {
  static String get _baseUrl =>
      "${BASE_URL.Urls().baseURL}advocate-working-experience-in-join-request";

  // ==================== ADD ====================
  static Future<AdvocateWorkingExperienceJoinRequest> addExperience({
    required AdvocateWorkingExperienceJoinRequest experience,
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
        body: jsonEncode(experience.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AdvocateWorkingExperienceJoinRequest.fromJson(
            jsonDecode(response.body));
      } else {
        throw Exception("Failed to add experience: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error adding experience: $e");
    }
  }

  // ==================== UPDATE ====================
  static Future<AdvocateWorkingExperienceJoinRequest> updateExperience({
    required AdvocateWorkingExperienceJoinRequest experience,
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
        body: jsonEncode(experience.toJson()),
      );

      if (response.statusCode == 200) {
        return AdvocateWorkingExperienceJoinRequest.fromJson(
            jsonDecode(response.body));
      } else {
        throw Exception("Failed to update experience: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error updating experience: $e");
    }
  }

  // ==================== FIND BY ID ====================
  static Future<AdvocateWorkingExperienceJoinRequest> findById(
      String id) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/$id"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return AdvocateWorkingExperienceJoinRequest.fromJson(
          jsonDecode(res.body));
    }
    throw Exception("Failed to find by ID: ${res.body}");
  }

  // ==================== FIND ALL ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>> findAll() async {
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
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find all: ${res.body}");
  }

  // ==================== FIND BY ADVOCATE ID ====================
  static Future<AdvocateWorkingExperienceJoinRequest> findByAdvocateId(
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
      return AdvocateWorkingExperienceJoinRequest.fromJson(
          jsonDecode(res.body));
    }
    throw Exception("Failed to find by advocateId: ${res.body}");
  }

  // ==================== FIND BY BAR ASSOCIATION ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>>
      findByBarAssociation(String barAssociation) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/bar-association/$barAssociation"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by bar association: ${res.body}");
  }

  // ==================== FIND BY BAR CONTROL ENROLMENT ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>> findByBarControl(
      String barControllEnrolment) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/bar-control/$barControllEnrolment"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by bar control: ${res.body}");
  }

  // ==================== FIND BY ENROLLMENT DATE AFTER ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>>
      findByEnrollmentDateAfter(String enrollmentDateIso) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/enrollment/after?enrollmentDate=$enrollmentDateIso"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by enrollment date after: ${res.body}");
  }

  // ==================== FIND BY ENROLLMENT DATE BEFORE ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>>
      findByEnrollmentDateBefore(String enrollmentDateIso) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/enrollment/before?enrollmentDate=$enrollmentDateIso"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by enrollment date before: ${res.body}");
  }

  // ==================== FIND BY PRACTICING COAT ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>>
      findByPracticingCoat(String practicingCoat) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/practicing-coat/$practicingCoat"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by practicing coat: ${res.body}");
  }

  // ==================== FIND BY PRIMARY PRACTICE ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>>
      findByPrimaryPractice(String primaryPractice) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/primary-practice/$primaryPractice"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by primary practice: ${res.body}");
  }

  // ==================== FIND BY LEGAL PRACTICE GTE ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>>
      findByLegalPracticeGte(int yearOfLegalPractice) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse(
          "$_baseUrl/legal-practice/gte?yearOfLegalPractice=$yearOfLegalPractice"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by legal practice gte: ${res.body}");
  }

  // ==================== FIND BY LEGAL PRACTICE LTE ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>>
      findByLegalPracticeLte(int yearOfLegalPractice) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse(
          "$_baseUrl/legal-practice/lte?yearOfLegalPractice=$yearOfLegalPractice"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by legal practice lte: ${res.body}");
  }

  // ==================== FIND BY CURRENT CHAMBER ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>>
      findByCurrentChamber(String currentChemberName) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("$_baseUrl/chamber/$currentChemberName"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception("Failed to find by chamber: ${res.body}");
  }

  // ==================== FIND BY PROFESSIONAL EXPERIENCE GTE ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>>
      findByProfessionalExperienceGte(int professionalExperience) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse(
          "$_baseUrl/professional-experience/gte?professionalExperience=$professionalExperience"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception(
        "Failed to find by professional experience gte: ${res.body}");
  }

  // ==================== FIND BY PROFESSIONAL EXPERIENCE LTE ====================
  static Future<List<AdvocateWorkingExperienceJoinRequest>>
      findByProfessionalExperienceLte(int professionalExperience) async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse(
          "$_baseUrl/professional-experience/lte?professionalExperience=$professionalExperience"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((e) => AdvocateWorkingExperienceJoinRequest.fromJson(e))
          .toList();
    }
    throw Exception(
        "Failed to find by professional experience lte: ${res.body}");
  }

  // ==================== DELETE ====================
  static Future<bool> deleteExperience({
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