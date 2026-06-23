// lib/LiveLocations/nominatim_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class NominatimSearchService {
  static const String baseUrl = 'https://nominatim.openstreetmap.org';
  
  // Multiple proxy options for reliability
  static const List<String> corsProxies = [
    'https://corsproxy.io/?',      // Primary
    'https://api.allorigins.win/raw?url=',  // Backup
    'https://cors-anywhere.herokuapp.com/', // Another option
  ];

  /// Main Search Function - Simplified and more reliable
  static Future<List<Map<String, dynamic>>> searchLocation(
      String query, {
        int limit = 15,
        String countryCodes = 'bd',
      }) async {
    if (query.trim().isEmpty) return [];

    final trimmedQuery = query.trim();
    print('🔍 Searching for: "$trimmedQuery"');

    // Try direct search with country filter first
    try {
      final results = await _searchWithRetry(trimmedQuery, limit, countryCodes);
      if (results.isNotEmpty) {
        print('✅ Found ${results.length} results');
        return results;
      }

      // If no results, try without country filter
      print('⚠️ No results with country, trying without...');
      final fallbackResults = await _searchWithRetry(trimmedQuery, limit, null);
      return fallbackResults;
    } catch (e) {
      print('❌ Search error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _searchWithRetry(
      String query, 
      int limit, 
      String? countryCodes,
      {int retries = 2}) async {
    
    // Try each proxy
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        // Build the URL
        final encodedQuery = Uri.encodeComponent(query);
        var target = '$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1';
        
        if (countryCodes != null && countryCodes.isNotEmpty) {
          target += '&countrycodes=$countryCodes';
        }

        String url;
        if (kIsWeb) {
          // Use a proxy for web
          final proxyIndex = attempt % corsProxies.length;
          final proxy = corsProxies[proxyIndex];
          //url = '$proxy${Uri.encodeComponent(target)}';
          url = target;
        } else {
          // Mobile/Desktop - direct request
          url = target;
        }

        print('📍 Attempt ${attempt + 1}: Requesting via ${kIsWeb ? "proxy" : "direct"}');
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'AdvocateChaiApp/1.0 (Contact: your-email@example.com)',
            'Accept': 'application/json',
            ..._getCorsHeaders(),
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          if (data.isNotEmpty) {
            print('✅ Success: ${data.length} results');
            return _parseResults(data);
          }
        } else {
          print('⚠️ Status ${response.statusCode}: ${response.body.substring(0, min(100, response.body.length))}');
        }
      } catch (e) {
        print('⚠️ Attempt ${attempt + 1} failed: $e');
        // Continue to next attempt
      }
    }
    
    return [];
  }

  static Map<String, String> _getCorsHeaders() {
    if (kIsWeb) {
      return {
        'Origin': 'https://your-domain.com', // Replace with your domain
      };
    }
    return {};
  }

  static List<Map<String, dynamic>> _parseResults(List<dynamic> data) {
    return data.map((item) {
      try {
        final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
        final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;
        final address = item['address'] ?? {};
        final displayName = item['display_name'] ?? '';

        // Skip results with invalid coordinates
        if (lat == 0 && lon == 0) return null;

        return {
          'name': _getCleanName(address, displayName),
          'display_name': displayName,
          'latitude': lat,
          'longitude': lon,
          'address': address,
          'type': item['type'] ?? '',
          'class': item['class'] ?? '',
          'location_type': _getLocationType(item['type'] ?? '', item['class'] ?? ''),
          'importance': item['importance'] ?? 0.0,
        };
      } catch (e) {
        print('⚠️ Error parsing item: $e');
        return null;
      }
    }).whereType<Map<String, dynamic>>().toList();
  }

  static String _getCleanName(Map<String, dynamic> address, String displayName) {
    final name = address['name'] ?? 
                address['city'] ?? 
                address['town'] ?? 
                address['village'] ?? 
                address['suburb'] ?? 
                address['state'];
    
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }
    
    // Fallback: get first part of display name
    return displayName.split(',').first.trim();
  }

  static String _getLocationType(String type, String class_) {
    if (type == 'city') return 'City';
    if (type == 'town') return 'Town';
    if (type == 'village') return 'Village';
    if (type == 'suburb') return 'Suburb';
    if (class_ == 'place') return 'Place';
    if (class_ == 'boundary') return 'Boundary';
    return 'Location';
  }

  // ==================== Other Methods ====================

  static Future<List<Map<String, dynamic>>> searchNearby({
    required double latitude,
    required double longitude,
    required String query,
    int limit = 10,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final target = '$baseUrl/search?q=$encodedQuery&format=json&limit=$limit'
          '&addressdetails=1&bounded=1'
          '&viewbox=${longitude - 0.05},${latitude - 0.05},${longitude + 0.05},${latitude + 0.05}';
      
      String url;
      if (kIsWeb) {
        url = '${corsProxies[0]}${Uri.encodeComponent(target)}';
      } else {
        url = target;
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'AdvocateChaiApp/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return _parseResults(data);
      }
      return [];
    } catch (e) {
      print('❌ Nearby error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> reverseGeocode(double latitude, double longitude) async {
    try {
      final target = '$baseUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1';
      
      String url;
      if (kIsWeb) {
        url = '${corsProxies[0]}${Uri.encodeComponent(target)}';
      } else {
        url = target;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'AdvocateChaiApp/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] ?? {};
        final displayName = data['display_name'] ?? '';
        return {
          'name': _getCleanName(address, displayName),
          'display_name': displayName,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        };
      }
      return null;
    } catch (e) {
      print('❌ Reverse geocode error: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> suggestLocations(String query, {int limit = 5}) async {
    if (query.trim().isEmpty) return [];
    final results = await searchLocation(query.trim(), limit: limit);
    results.sort((a, b) => (b['importance'] ?? 0.0).compareTo(a['importance'] ?? 0.0));
    return results;
  }
}

// Helper function
int min(int a, int b) => a < b ? a : b;