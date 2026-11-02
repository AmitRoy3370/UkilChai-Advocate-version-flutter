// lib/LiveLocations/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart'; // ✅ এই লাইনটি যোগ করুন

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  bool _isServiceEnabled = false;

  Position? get currentPosition => _currentPosition;

  Future<bool> checkAndRequestPermissions() async {
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

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('📍 Current Location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      return _currentPosition;
      
    } catch (e) {
      print('❌ Error getting location: $e');
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