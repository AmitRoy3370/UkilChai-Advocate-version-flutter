// lib/services/live_location_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../LiveLocations/live_location_model.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class LiveLocationService {
  static String get baseUrl => BASE_URL.Urls().baseURL;

  // ================= HEARTBEAT =================
// lib/LiveLocations/live_location_service.dart - Part of sendHeartbeat
static Future<UserLiveLocationDataResponse?> sendHeartbeat({
  required String userId,
  required double latitude,
  required double longitude,
  required String locationName,
  String? advocateId,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    if (token == null) {
      print('❌ Token not found');
      return null;
    }

    final body = {
      'userId': userId,
      'lattitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      if (advocateId != null && advocateId.isNotEmpty) 'advocateId': advocateId,
    };

    print('📍 Sending heartbeat: $body');

    final response = await http.put(
      Uri.parse('${baseUrl}user-live-location/heartbeat/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('✅ Heartbeat sent successfully');
      return UserLiveLocationDataResponse.fromJson(data); // ✅ Returns LiveLocationData
    } else {
      print('❌ Heartbeat failed: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (e) {
    print('❌ Heartbeat error: $e');
    return null;
  }
}

  // ================= GET ALL =================
  // ✅ GET - Returns UserLiveLocationDataResponse DTO
  static Future<List<UserLiveLocationDataResponse>> getAllLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        print('❌ Token not found');
        return [];
      }

      final response = await http.get(
        Uri.parse('${baseUrl}user-live-location/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserLiveLocationDataResponse.fromJson(json)).toList();
      } else {
        print('❌ Failed to get locations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting locations: $e');
      return [];
    }
  }

  // ================= GET BY USER ID =================
  // ✅ GET - Returns UserLiveLocationDataResponse DTO
  static Future<UserLiveLocationDataResponse?> getLocationByUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        print('❌ Token not found');
        return null;
      }

      final response = await http.get(
        Uri.parse('${baseUrl}user-live-location/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return UserLiveLocationDataResponse.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }


  // ================= GET BY ADVOCATE ID =================
  // ✅ GET - Returns UserLiveLocationDataResponse DTO
  static Future<UserLiveLocationDataResponse?> getLocationByAdvocateId(String advocateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        print('❌ Token not found');
        return null;
      }

      final response = await http.get(
        Uri.parse('${baseUrl}user-live-location/advocate/$advocateId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return UserLiveLocationDataResponse.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error getting advocate location: $e');
      return null;
    }
  }

  // ================= GET BY ADVOCATE IDS LIST =================
  // ✅ POST - Returns List<UserLiveLocationDataResponse> DTO
  static Future<List<UserLiveLocationDataResponse>> getLocationsByAdvocates(
    List<String> advocateIds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        print('❌ Token not found');
        return [];
      }

      final response = await http.post(
        Uri.parse('${baseUrl}user-live-location/advocates/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(advocateIds),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserLiveLocationDataResponse.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error getting advocate locations: $e');
      return [];
    }
  }

  // ================= GET BY USER IDS LIST =================
  // ✅ POST - Returns List<UserLiveLocationDataResponse> DTO
  static Future<List<UserLiveLocationDataResponse>> getLocationsByUsers(
    List<String> userIds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        print('❌ Token not found');
        return [];
      }

      final response = await http.post(
        Uri.parse('${baseUrl}user-live-location/users/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userIds),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserLiveLocationDataResponse.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error getting user locations: $e');
      return [];
    }
  }

  // ================= GET BY LOCATION NAME =================
  // ✅ GET - Returns List<UserLiveLocationDataResponse> DTO
  static Future<List<UserLiveLocationDataResponse>> getLocationsByLocationName(
    String locationName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      if (token == null) {
        print('❌ Token not found');
        return [];
      }

      final response = await http.get(
        Uri.parse('${baseUrl}user-live-location/location-name?locationName=$locationName'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserLiveLocationDataResponse.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error getting locations by name: $e');
      return [];
    }
  }
}