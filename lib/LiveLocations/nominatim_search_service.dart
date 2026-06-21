// lib/LiveLocations/nominatim_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class NominatimSearchService {
  static const String baseUrl = 'https://nominatim.openstreetmap.org';

  // ✅ Web-এর জন্য CORS proxy
  static const String corsProxy = 'https://corsproxy.io/?';

  /// ✅ Main search with partial name support
  static Future<List<Map<String, dynamic>>> searchLocation(
      String query, {
        int limit = 15, // ✅ Increased limit for better partial matches
        String countryCodes = 'bd',
      }) async {
    if (query.isEmpty || query.trim().isEmpty) {
      return [];
    }

    final trimmedQuery = query.trim();
    print('🔍 Searching for: "$trimmedQuery"');

    try {
      // ✅ Try with country filter first
      List<Map<String, dynamic>> results = await _searchWithCountry(trimmedQuery, limit, countryCodes);

      if (results.isNotEmpty) {
        print('✅ Found ${results.length} results with country filter');
        return results;
      }

      // ✅ If no results, try without country filter
      print('⚠️ No results with country filter, trying without...');
      results = await _searchWithoutCountry(trimmedQuery, limit);

      if (results.isNotEmpty) {
        print('✅ Found ${results.length} results without country filter');
        return results;
      }

      // ✅ If still no results, try with wildcard search
      print('⚠️ No results, trying partial/wildcard search...');
      results = await _searchWithWildcard(trimmedQuery, limit);

      if (results.isNotEmpty) {
        print('✅ Found ${results.length} results with wildcard search');
        return results;
      }

      // ✅ Final fallback: search with auto-complete
      print('⚠️ Trying auto-complete search...');
      results = await _searchWithAutocomplete(trimmedQuery, limit);

      if (results.isNotEmpty) {
        print('✅ Found ${results.length} results with auto-complete');
        return results;
      }

      print('❌ No results found for: "$trimmedQuery"');
      return [];

    } catch (e) {
      print('❌ Search error: $e');

      // ✅ Try fallback methods
      try {
        return await _searchWithoutCountry(trimmedQuery, limit);
      } catch (_) {
        try {
          return await _searchWithWildcard(trimmedQuery, limit);
        } catch (_) {
          return [];
        }
      }
    }
  }

  // ✅ Search with country filter
  static Future<List<Map<String, dynamic>>> _searchWithCountry(
      String query,
      int limit,
      String countryCodes,
      ) async {
    final encodedQuery = Uri.encodeComponent(query);

    String url;
    if (kIsWeb) {
      url = '$corsProxy$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1&countrycodes=$countryCodes';
    } else {
      url = '$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1&countrycodes=$countryCodes';
    }

    return await _makeSearchRequest(url);
  }

  // ✅ Search without country filter
  static Future<List<Map<String, dynamic>>> _searchWithoutCountry(
      String query,
      int limit,
      ) async {
    final encodedQuery = Uri.encodeComponent(query);

    String url;
    if (kIsWeb) {
      url = '$corsProxy$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1';
    } else {
      url = '$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1';
    }

    return await _makeSearchRequest(url);
  }

  // ✅ Wildcard search (for partial matches)
  static Future<List<Map<String, dynamic>>> _searchWithWildcard(
      String query,
      int limit,
      ) async {
    // ✅ Add wildcards for better partial matching
    final wildcardQuery = '*$query*';
    final encodedQuery = Uri.encodeComponent(wildcardQuery);

    String url;
    if (kIsWeb) {
      url = '$corsProxy$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1';
    } else {
      url = '$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1';
    }

    return await _makeSearchRequest(url);
  }

  // ✅ Autocomplete search (for partial names)
  static Future<List<Map<String, dynamic>>> _searchWithAutocomplete(
      String query,
      int limit,
      ) async {
    final encodedQuery = Uri.encodeComponent(query);

    // ✅ Add autocomplete parameter
    String url;
    if (kIsWeb) {
      url = '$corsProxy$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1&featuretype=settlement&class=place';
    } else {
      url = '$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1&featuretype=settlement&class=place';
    }

    final results = await _makeSearchRequest(url);

    // ✅ If no results, try with broader search
    if (results.isEmpty) {
      if (kIsWeb) {
        url = '$corsProxy$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1';
      } else {
        url = '$baseUrl/search?q=$encodedQuery&format=json&limit=$limit&addressdetails=1';
      }
      return await _makeSearchRequest(url);
    }

    return results;
  }

  // ✅ Make search request with proper headers
  static Future<List<Map<String, dynamic>>> _makeSearchRequest(String url) async {
    try {
      print('📍 Requesting: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'AdvocateChaiApp/1.0',
          'Accept': 'application/json',
          'Accept-Language': 'en,en-BD',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return _parseResults(data);
      } else {
        print('❌ Request failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Request error: $e');
      return [];
    }
  }

  // ✅ Parse search results
  static List<Map<String, dynamic>> _parseResults(List<dynamic> data) {
    return data.map((item) {
      final lat = double.tryParse(item['lat']?.toString() ?? '0') ?? 0.0;
      final lon = double.tryParse(item['lon']?.toString() ?? '0') ?? 0.0;

      final address = item['address'] ?? {};
      final displayName = item['display_name'] ?? '';

      // ✅ Get clean name with priority
      String cleanName = _getCleanName(address, displayName);

      // ✅ Get location type
      String type = item['type'] ?? '';
      String class_ = item['class'] ?? '';

      String locationType = _getLocationType(type, class_);

      return {
        'name': cleanName,
        'display_name': displayName,
        'latitude': lat,
        'longitude': lon,
        'address': address,
        'type': type,
        'class': class_,
        'location_type': locationType,
        'importance': item['importance'] ?? 0.0,
      };
    }).toList();
  }

  // ✅ Get clean name from address
  static String _getCleanName(Map<String, dynamic> address, String displayName) {
    // Priority order for name
    final priority = [
      address['name'],
      address['road'],
      address['city'],
      address['town'],
      address['village'],
      address['suburb'],
      address['county'],
      address['state'],
      address['country'],
    ];

    // Find first non-null and non-empty
    for (var name in priority) {
      if (name != null && name.toString().isNotEmpty) {
        return name.toString();
      }
    }

    // Fallback to display name
    if (displayName.isNotEmpty) {
      final parts = displayName.split(',');
      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
        return parts[0].trim();
      }
      return displayName;
    }

    return 'Unknown Location';
  }

  // ✅ Get location type for better UX
  static String _getLocationType(String type, String class_) {
    if (type == 'city') return 'City';
    if (type == 'town') return 'Town';
    if (type == 'village') return 'Village';
    if (type == 'suburb') return 'Suburb';
    if (type == 'neighbourhood') return 'Neighborhood';
    if (class_ == 'place') return 'Place';
    if (class_ == 'boundary') return 'Area';
    if (class_ == 'landuse') return 'Landmark';
    return 'Location';
  }

  // ✅ Search nearby places with partial support
  static Future<List<Map<String, dynamic>>> searchNearby({
    required double latitude,
    required double longitude,
    required String query,
    int radius = 5000,
    int limit = 10,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);

      // ✅ Add wildcard for partial matches in nearby search
      final wildcardQuery = '*$encodedQuery*';
      final encodedWildcard = Uri.encodeComponent(wildcardQuery);

      String url;
      if (kIsWeb) {
        url = '$corsProxy$baseUrl/search?q=$encodedWildcard&format=json&limit=$limit'
            '&addressdetails=1&bounded=1&viewbox=${longitude - 0.05},${latitude - 0.05},${longitude + 0.05},${latitude + 0.05}';
      } else {
        url = '$baseUrl/search?q=$encodedWildcard&format=json&limit=$limit'
            '&addressdetails=1&bounded=1&viewbox=${longitude - 0.05},${latitude - 0.05},${longitude + 0.05},${latitude + 0.05}';
      }

      return await _makeSearchRequest(url);
    } catch (e) {
      print('❌ Search nearby error: $e');
      return [];
    }
  }

  // ✅ Reverse geocoding with fallback
  static Future<Map<String, dynamic>?> reverseGeocode(
      double latitude,
      double longitude,
      ) async {
    try {
      String url;
      if (kIsWeb) {
        url = '$corsProxy$baseUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1';
      } else {
        url = '$baseUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'AdvocateChaiApp/1.0',
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

  // ✅ Suggest locations (for auto-complete UI)
  static Future<List<Map<String, dynamic>>> suggestLocations(
      String query, {
        int limit = 5,
      }) async {
    if (query.isEmpty || query.trim().isEmpty) {
      return [];
    }

    // ✅ Use autocomplete search for suggestions
    final results = await _searchWithAutocomplete(query.trim(), limit);

    // ✅ Sort by importance for better suggestions
    results.sort((a, b) => (b['importance'] ?? 0.0).compareTo(a['importance'] ?? 0.0));

    return results;
  }
}