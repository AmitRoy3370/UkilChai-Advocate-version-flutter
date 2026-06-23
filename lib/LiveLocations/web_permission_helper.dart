// lib/LiveLocations/web_permission_helper.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class WebPermissionHelper {
  // ✅ NEW: Check if geolocation is available in browser
  static bool isGeolocationSupported() {
    if (!kIsWeb) return false;
    try {
      // ignore: undefined_prefixed_name
      return true; // Most modern browsers support it
    } catch (e) {
      return false;
    }
  }

  // ✅ NEW: Get permission status message
  static String getPermissionMessage() {
    if (!kIsWeb) return 'Not applicable';
    return 'Please allow location access in your browser settings';
  }

  // ✅ NEW: Instructions for user
  static String getInstructions() {
    if (!kIsWeb) return '';
    return '🔧 Click the lock icon in the address bar and allow location access';
  }
}