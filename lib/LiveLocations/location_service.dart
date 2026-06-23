// lib/LiveLocations/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:geocoding/geocoding.dart'; // ✅ এই লাইনটি যোগ করুন

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  bool _isServiceEnabled = false;

  Position? get currentPosition => _currentPosition;

  Future<bool> checkAndRequestPermissions() async {
    // ✅ FIX: Web-specific permission handling
    if (kIsWeb) {
      print('🌐 Web: Checking geolocation permission');
      try {
        // Check if browser supports geolocation
        final hasPermission = await _checkWebGeolocation();
        print('🌐 Web permission result: $hasPermission');
        return hasPermission;
      } catch (e) {
        print('❌ Web permission error: $e');
        return false;
      }
    }

    // Mobile permission handling
    PermissionStatus permission = await Permission.location.status;
    
    if (permission.isDenied) {
      permission = await Permission.location.request();
    }
    
    if (permission.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return permission.isGranted;
  }


  // ✅ NEW: Web geolocation check
  Future<bool> _checkWebGeolocation() async {
    try {
      // Try to get position with a short timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      
      return position != null;
    } catch (e) {
      print('⚠️ Web geolocation check failed: $e');
      // Don't return false here - let the actual getCurrentLocation handle it
      return true;
    }
  }


  Future<Position?> getCurrentLocation() async {
    try {
      print('📍 Getting current location...');
      
      bool hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        print('❌ Location permission denied');
        return null;
      }

      // ✅ FIX: Web uses the same Geolocator - it works on web too!
      // The Geolocator package handles web internally
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // ✅ FIX: Validate coordinates are not 0,0
      if (_currentPosition != null && 
          _currentPosition!.latitude == 0 && 
          _currentPosition!.longitude == 0) {
        print('⚠️ Got invalid coordinates (0,0) - retrying...');
        // Retry with lower accuracy
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
      }
      
      print('📍 Current Location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      return _currentPosition;
      
    } catch (e) {
      print('❌ Error getting location: $e');
      
      // ✅ NEW: Show helpful message for web
      if (kIsWeb) {
        print('🔧 TIP: For web, allow location access in your browser');
        print('🔧 Click the lock icon in address bar → Allow location');
      }
      return null;
    }
  }

  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String name = '';
        if (place.street != null && place.street!.isNotEmpty) {
          name += place.street!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          name += name.isEmpty ? place.locality! : ', ${place.locality!}';
        }
        if (place.country != null && place.country!.isNotEmpty) {
          name += name.isEmpty ? place.country! : ', ${place.country!}';
        }
        return name.isNotEmpty ? name : 'Unknown Location';
      }
      return 'Location ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      print('❌ Error getting location name: $e');
      return 'Location ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }

  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}