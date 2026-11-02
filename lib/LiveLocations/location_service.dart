// lib/LiveLocations/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

// Web-only imports for the native browser fallback
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  bool _isServiceEnabled = false;

  Position? get currentPosition => _currentPosition;

  Future<bool> checkAndRequestPermissions() async {
    if (kIsWeb) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    }

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

  Future<Position?> _getWebLocationViaJs() async {
    try {
      final completer = Completer<Position?>();

      final options = web.PositionOptions(
        enableHighAccuracy: false,
        timeout: 15000,
        maximumAge: 60000,
      );

      web.window.navigator.geolocation.getCurrentPosition(
        (web.GeolocationPosition position) {
          completer.complete(Position(
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            timestamp: DateTime.now(),
            accuracy: position.coords.accuracy,
            altitude: position.coords.altitude ?? 0,
            altitudeAccuracy: position.coords.altitudeAccuracy ?? 0,
            heading: position.coords.heading ?? 0,
            headingAccuracy: 0,
            speed: position.coords.speed ?? 0,
            speedAccuracy: 0,
          ));
        }.toJS,
        (web.GeolocationPositionError error) {
          print('❌ JS geolocation error: ${error.message}');
          completer.complete(null);
        }.toJS,
        options,
      );

      return await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => null,
      );
    } catch (e) {
      print('❌ JS geolocation threw: $e');
      return null;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        print('❌ Location permission denied');
        return null;
      }

      _isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isServiceEnabled) {
        print('❌ Location services disabled');
        return null;
      }

      // ✅ ONLY try cached position on mobile — it throws on web
      if (!kIsWeb) {
        try {
          final lastPos = await Geolocator.getLastKnownPosition();
          if (lastPos != null) {
            print('📍 Cached: ${lastPos.latitude}, ${lastPos.longitude}');
            _currentPosition = lastPos;
            return _currentPosition;
          }
        } catch (_) {}
      }

      // ✅ Try the plugin's live location
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: kIsWeb ? LocationAccuracy.low : LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );
        if (_currentPosition != null) {
          print('📍 Plugin Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
          return _currentPosition;
        }
      } catch (e) {
        print('❌ Plugin getCurrentPosition failed: $e');
      }

      // ✅ On Web: fall back to native browser API
      if (kIsWeb) {
        print('🔄 Falling back to native browser geolocation...');
        final jsPos = await _getWebLocationViaJs();
        if (jsPos != null) {
          print('📍 JS Location: ${jsPos.latitude}, ${jsPos.longitude}');
          _currentPosition = jsPos;
          return _currentPosition;
        }
      }

      print('❌ All location methods failed');
      return null;
    } catch (e) {
      print('❌ Unhandled error getting location: $e');
      return null;
    }
  }

  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

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