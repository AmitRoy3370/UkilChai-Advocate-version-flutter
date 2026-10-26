// lib/CompanyPages/subscription_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../CompanyPages/subscription.dart';
import '../Utils/BaseURL.dart' as baseURL;

class SubscriptionService {
  final String baseUrl = baseURL.Urls().baseURL;
  String? _token;

  SubscriptionService({String? token}) {
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
    final headers = <String, String>{};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ✅ Helper method to detect content type
  String _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // ==================== ADD SUBSCRIPTION ====================
  Future<Subscription> addSubscription({
    required Subscription subscription,
    required String userId,
    required PlatformFile? signatureFile,
  }) async {
    final token = await _getToken();

    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('========== ADD SUBSCRIPTION DEBUG ==========');
    print('User ID: $userId');
    print('Subscription Data: ${subscription.toJson()}');
    print('Signature File: ${signatureFile?.name ?? 'null'}');
    print('===========================================');

    final uri = Uri.parse('${baseUrl}subscriptions?userId=$userId');
    final request = http.MultipartRequest('POST', uri)..headers.addAll(headers);

    // Add subscription as JSON
    final subscriptionJson = jsonEncode(subscription.toJson());
    print('📤 Subscription JSON: $subscriptionJson');
    
    request.files.add(
      http.MultipartFile.fromString(
        'subscription',
        subscriptionJson,
        contentType: MediaType('application', 'json'),
      ),
    );

    // Add signature file with proper content type
    if (signatureFile != null && signatureFile.bytes != null && signatureFile.bytes!.isNotEmpty) {
      try {
        final contentType = _getContentType(signatureFile.name);
        print('📎 Signature File: ${signatureFile.name}, Content-Type: $contentType');
        request.files.add(
          http.MultipartFile.fromBytes(
            'signature',
            signatureFile.bytes!,
            filename: signatureFile.name,
            contentType: MediaType.parse(contentType),
          ),
        );
      } catch (e) {
        print('❌ Error adding signature file: $e');
        request.files.add(
          http.MultipartFile.fromBytes(
            'signature',
            signatureFile.bytes!,
            filename: signatureFile.name,
          ),
        );
      }
    } else {
      print('ℹ️ No signature file provided');
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    print('Add Subscription Status: ${response.statusCode}');
    print('Response Body: ${responseBody.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(responseBody.body);
      if (data != null) {
        return Subscription.fromJson(data);
      } else {
        throw Exception('Failed to add subscription: Empty response');
      }
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: Check user permissions/roles');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to add subscription: ${response.statusCode} - ${responseBody.body}');
    }
  }

  // ==================== UPDATE SUBSCRIPTION ====================
  Future<Subscription> updateSubscription({
    required String id,
    required Subscription subscription,
    required String userId,
    required PlatformFile? signatureFile,
    bool removeSignature = false,
  }) async {
    final token = await _getToken();

    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    print('========== UPDATE SUBSCRIPTION DEBUG ==========');
    print('ID: $id');
    print('User ID: $userId');
    print('Subscription Data: ${subscription.toJson()}');
    print('Signature File: ${signatureFile?.name ?? 'null'}');
    print('Remove Signature: $removeSignature');
    print('===========================================');

    final uri = Uri.parse('${baseUrl}subscriptions/$id?userId=$userId');
    final request = http.MultipartRequest('PUT', uri)..headers.addAll(headers);

    // ✅ Create clean subscription data
    final Map<String, dynamic> subscriptionData = {
      'companyId': subscription.companyId,
      'subscriberName': subscription.subscriberName,
      'numberOfShare': subscription.numberOfShare,
    };
    
    // ✅ Add signatureId if it exists and not being removed
    if (subscription.signatureId != null && subscription.signatureId!.isNotEmpty && !removeSignature) {
      subscriptionData['signatureId'] = subscription.signatureId;
    }
    
    // ✅ Add id if it exists
    if (id != null && id.isNotEmpty) {
      subscriptionData['id'] = id;
    }

    final subscriptionJson = jsonEncode(subscriptionData);
    print('📤 Subscription JSON: $subscriptionJson');
    
    request.files.add(
      http.MultipartFile.fromString(
        'subscription',
        subscriptionJson,
        contentType: MediaType('application', 'json'),
      ),
    );

    // ✅ Handle signature cases
    if (removeSignature) {
      print('🔄 Removing Signature');
      request.files.add(
        http.MultipartFile.fromBytes(
          'signature',
          Uint8List(0),
          filename: 'remove_signature.pdf',
        ),
      );
    } else if (signatureFile != null && signatureFile.bytes != null && signatureFile.bytes!.isNotEmpty) {
      try {
        final contentType = _getContentType(signatureFile.name);
        print('📎 New Signature File: ${signatureFile.name}, Content-Type: $contentType');
        request.files.add(
          http.MultipartFile.fromBytes(
            'signature',
            signatureFile.bytes!,
            filename: signatureFile.name,
            contentType: MediaType.parse(contentType),
          ),
        );
      } catch (e) {
        print('❌ Error adding signature file: $e');
        request.files.add(
          http.MultipartFile.fromBytes(
            'signature',
            signatureFile.bytes!,
            filename: signatureFile.name,
          ),
        );
      }
    } else {
      print('🔄 Keeping existing Signature');
    }

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    print('✅ Update Subscription Status: ${response.statusCode}');
    print('✅ Response Body: "${responseBody.body}"');

    if (response.statusCode == 200) {
      if (responseBody.body.isNotEmpty && responseBody.body.trim() != '') {
        try {
          final data = jsonDecode(responseBody.body);
          print('📥 Parsed response data: $data');
          
          if (data != null) {
            return Subscription.fromJson(data);
          }
        } catch (e) {
          print('⚠️ Error parsing response: $e');
        }
      }
      
      // ✅ If we reach here, either response was empty or parsing failed
      print('✅ Update successful, returning subscription with ID: $id');
      
      return Subscription(
        id: id,
        companyId: subscription.companyId,
        subscriberName: subscription.subscriberName,
        numberOfShare: subscription.numberOfShare,
        signatureId: removeSignature ? null : subscription.signatureId,
      );
      
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to update subscription: ${response.statusCode} - ${responseBody.body}');
    }
  }

  // ==================== GET ALL SUBSCRIPTIONS ====================
  Future<List<Subscription>> getAllSubscriptions() async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}subscriptions');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Subscription.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch subscriptions: ${response.statusCode}');
    }
  }

  // ==================== GET SUBSCRIPTION BY ID ====================
  Future<Subscription> getSubscriptionById(String id) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}subscriptions/$id');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Subscription.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Subscription not found');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch subscription: ${response.statusCode}');
    }
  }

  // ==================== GET SUBSCRIPTIONS BY COMPANY ID ====================
  Future<List<Subscription>> getSubscriptionsByCompanyId(String companyId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}subscriptions/company/$companyId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Subscription.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch subscriptions: ${response.statusCode}');
    }
  }

  // ==================== GET SUBSCRIPTIONS BY SUBSCRIBER NAME ====================
  Future<List<Subscription>> getSubscriptionsBySubscriberName(String subscriberName) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}subscriptions/subscriber/search?name=$subscriberName');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Subscription.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to search subscriptions: ${response.statusCode}');
    }
  }

  // ==================== GET SUBSCRIPTIONS BY SIGNATURE ID ====================
  Future<List<Subscription>> getSubscriptionsBySignatureId(String signatureId) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}subscriptions/signature/$signatureId');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Subscription.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch subscriptions: ${response.statusCode}');
    }
  }

  // ==================== GET SUBSCRIPTIONS BY SHARE RANGE (LTE) ====================
  Future<List<Subscription>> getSubscriptionsByCompanyIdAndShareLte({
    required String companyId,
    required int lteShares,
  }) async {
    await _getToken();

    final uri = Uri.parse(
      '${baseUrl}subscriptions/company/$companyId/shares?lte=$lteShares'
    );
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Subscription.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch subscriptions: ${response.statusCode}');
    }
  }

  // ==================== GET SUBSCRIPTIONS BY SHARE RANGE (GTE) ====================
  Future<List<Subscription>> getSubscriptionsByCompanyIdAndShareGte({
    required String companyId,
    required int gteShares,
  }) async {
    await _getToken();

    final uri = Uri.parse(
      '${baseUrl}subscriptions/company/$companyId/shares?gte=$gteShares'
    );
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Subscription.fromJson(e)).toList();
      }
      return [];
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to fetch subscriptions: ${response.statusCode}');
    }
  }

  // ==================== DELETE SUBSCRIPTION ====================
  Future<bool> deleteSubscription({
    required String id,
    required String userId,
  }) async {
    await _getToken();

    final uri = Uri.parse('${baseUrl}subscriptions/$id?userId=$userId');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: You do not have permission');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      return false;
    }
  }
}