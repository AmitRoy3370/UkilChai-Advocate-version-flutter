// RegistrationPage/UserGenderService.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../RegistrationPage/UserGender.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../RegistrationPage/Gender.dart';

class UserGenderService {
  final Dio _dio;
  final String baseUrl;

  UserGenderService({
    Dio? dio,
    this.baseUrl = 'https://ukilchai.abrdns.com', // Make sure this matches Postman
  }) : _dio = dio ?? Dio() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Log the request for debugging
          if (kDebugMode) {
            print('🚀 Request: ${options.method} ${options.path}');
            print('📋 Headers: ${options.headers}');
            print('📦 Data: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('✅ Response: ${response.statusCode}');
            print('📦 Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            print('❌ Error: ${error.message}');
            print('📦 Response: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Get auth token from SharedPreferences
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (kDebugMode) {
        print('🔑 Token: ${token != null ? 'Found' : 'Not found'}');
        if (token != null) {
          print('🔑 Token starts with: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        }
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error getting token: $e');
      }
      return null;
    }
  }

  // ============ CREATE ============
  /// POST /api/user-gender/create?userId={userId}
  Future<UserGender> createUserGender({
    required String userId,
    required Gender gender,
  }) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      // Build the URL with query parameter
      final String url = '$baseUrl/api/user-gender/create?userId=$userId';
      
      // Create the request body
      final Map<String, dynamic> requestBody = {
        'userId': userId,
        'gender': gender.name, // This will be "MALE", "FEMALE", or "OTHER"
      };

      if (kDebugMode) {
        print('📤 Creating gender for user: $userId');
        print('📤 URL: $url');
        print('📤 Body: $requestBody');
        print('📤 Token: Bearer $token');
      }

      final response = await _dio.post(
        url,
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (kDebugMode) {
        print('📡 Response status: ${response.statusCode}');
        print('📡 Response data: ${response.data}');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return UserGender.fromJson(response.data as Map<String, dynamic>);
        } else {
          throw Exception('Invalid response format: ${response.data}');
        }
      } else {
        throw Exception('Failed to create user gender: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Dio Error: ${e.message}');
        print('❌ Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error creating user gender: $e');
    }
  }

  // ============ UPDATE ============
  /// PUT /api/user-gender/update/{id}?userId={userId}
  Future<UserGender> updateUserGender({
    required String id,
    required String userId,
    required UserGender userGender,
  }) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final String url = '$baseUrl/api/user-gender/update/$id?userId=$userId';

      if (kDebugMode) {
        print('📤 Updating gender for user: $userId');
        print('📤 URL: $url');
        print('📤 Data: ${userGender.toJson()}');
      }

      final response = await _dio.put(
        url,
        data: userGender.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (kDebugMode) {
        print('📡 Response status: ${response.statusCode}');
        print('📡 Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return UserGender.fromJson(response.data as Map<String, dynamic>);
        } else {
          throw Exception('Invalid response format: ${response.data}');
        }
      } else {
        throw Exception('Failed to update user gender: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error updating user gender: $e');
    }
  }

  // ============ FIND BY USER ID ============
  /// GET /api/user-gender/find-by-user/{userId}
  Future<UserGender> findByUserId(String userId) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final String url = '$baseUrl/api/user-gender/find-by-user/$userId';

      if (kDebugMode) {
        print('📤 Finding gender for user: $userId');
        print('📤 URL: $url');
      }

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (kDebugMode) {
        print('📡 Response status: ${response.statusCode}');
        print('📡 Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return UserGender.fromJson(response.data as Map<String, dynamic>);
        } else {
          throw Exception('Invalid response format: ${response.data}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('User gender not found');
      } else {
        throw Exception('Failed to find user gender: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('User gender not found');
      }
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding user gender by user ID: $e');
    }
  }

  // ============ FIND BY ID ============
  /// GET /api/user-gender/find/{id}
  Future<UserGender> findById(String id) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final String url = '$baseUrl/api/user-gender/find/$id';

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return UserGender.fromJson(response.data as Map<String, dynamic>);
        } else {
          throw Exception('Invalid response format: ${response.data}');
        }
      } else {
        throw Exception('Failed to find user gender: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding user gender: $e');
    }
  }

  // ============ FIND ALL ============
  /// GET /api/user-gender/find-all
  Future<List<UserGender>> findAll() async {
    try {
      final token = await getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final String url = '$baseUrl/api/user-gender/find-all';

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data as List;
          return data.map((json) => UserGender.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          throw Exception('Invalid response format: ${response.data}');
        }
      } else {
        throw Exception('Failed to find all user genders: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding all user genders: $e');
    }
  }

  // ============ FIND BY GENDER ============
  /// GET /api/user-gender/find-by-gender?gender={gender}
  Future<List<UserGender>> findByGender(Gender gender) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final String url = '$baseUrl/api/user-gender/find-by-gender?gender=${gender.name}';

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data as List;
          return data.map((json) => UserGender.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          throw Exception('Invalid response format: ${response.data}');
        }
      } else {
        throw Exception('Failed to find user genders by gender: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding user genders by gender: $e');
    }
  }

  // ============ FIND BY USER IDS ============
  /// POST /api/user-gender/find-by-user-ids
  Future<List<UserGender>> findByUserIds(List<String> userIds) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final String url = '$baseUrl/api/user-gender/find-by-user-ids';

      final response = await _dio.post(
        url,
        data: userIds,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data as List;
          return data.map((json) => UserGender.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          throw Exception('Invalid response format: ${response.data}');
        }
      } else {
        throw Exception('Failed to find user genders by user IDs: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error finding user genders by user IDs: $e');
    }
  }

  // ============ DELETE ============
  /// DELETE /api/user-gender/delete/{id}?userId={userId}
  Future<bool> deleteUserGender({
    required String id,
    required String userId,
  }) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final String url = '$baseUrl/api/user-gender/delete/$id?userId=$userId';

      final response = await _dio.delete(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete user gender: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error deleting user gender: $e');
    }
  }

  // ============ ERROR HANDLING ============
  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (kDebugMode) {
        print('⚠️ Dio Error: $statusCode');
        print('⚠️ Response: $data');
      }

      switch (statusCode) {
        case 400:
          return Exception('Bad Request: ${_extractErrorMessage(data)}');
        case 401:
          return Exception('Unauthorized: Please check your authentication');
        case 403:
          return Exception('Forbidden: You do not have permission');
        case 404:
          return Exception('Not Found: ${_extractErrorMessage(data)}');
        case 409:
          return Exception('Conflict: ${_extractErrorMessage(data)}');
        case 500:
          return Exception('Internal Server Error: Please try again later');
        default:
          return Exception('Error ${statusCode}: ${_extractErrorMessage(data)}');
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout: Please check your internet connection');
    } else if (e.type == DioExceptionType.sendTimeout) {
      return Exception('Send timeout: Please try again');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('Receive timeout: Please try again');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('Connection error: Please check your internet connection');
    } else {
      return Exception('Network error: ${e.message}');
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data == null) return 'Unknown error';
    if (data is String) return data;
    if (data is Map) {
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('error')) return data['error'].toString();
      if (data.containsKey('Error')) return data['Error'].toString();
      return data.toString();
    }
    return data.toString();
  }
}