// lib/LiveLocations/live_location_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../LiveLocations/live_location_model.dart';
import '../LiveLocations/live_location_service.dart';
import '../LiveLocations/location_service.dart';

class LiveLocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  List<UserLiveLocationDataResponse> _allLocations = [];
  UserLiveLocationDataResponse? _myLocation; // ✅ Changed to Response type
  bool _isLoading = false;
  bool _isTracking = false;
  Timer? _heartbeatTimer;
  Timer? _refreshTimer;
  String? _currentUserId;
  String? _advocateId;
  bool _isInitialized = false;
  String _myUserName = '';

  List<UserLiveLocationDataResponse> get allLocations => _allLocations;
  UserLiveLocationDataResponse? get myLocation => _myLocation;
  bool get isLoading => _isLoading;
  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;

  List<UserLiveLocationDataResponse> get onlineAdvocates {
    return _allLocations.where((loc) => loc.isAdvocate).toList();
  }

  List<UserLiveLocationDataResponse> get onlineUsers {
    return _allLocations.where((loc) => !loc.isAdvocate).toList();
  }

  Future<void> startTracking({
    required String userId,
    required String userName,
    String? advocateId,
  }) async {
    if (_isTracking && _currentUserId == userId) {
      print('⚠️ Already tracking user: $userId');
      return;
    }
    
    _currentUserId = userId;
    _myUserName = userName;
    _advocateId = advocateId;
    _isTracking = true;
    _isInitialized = false;

    print('📍 Starting tracking for user: $userId');

    await _updateLocation();

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) async {
        if (_isTracking) {
          await _updateLocation();
        }
      },
    );

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        if (_isTracking) {
          await refreshLocations();
        }
      },
    );

    _isInitialized = true;
    notifyListeners();
    print('✅ Live Location Tracking Started');
  }

  Future<void> _updateLocation() async {
    if (_currentUserId == null || !_isTracking) {
      print('⚠️ Cannot update location - not tracking');
      return;
    }

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        print('❌ No position available');
        return;
      }

      final locationName = await _locationService.getLocationName(
        position.latitude,
        position.longitude,
      );

      // ✅ Send heartbeat and get LiveLocationData
      final result = await LiveLocationService.sendHeartbeat(
        userId: _currentUserId!,
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
        advocateId: _advocateId,
      );

      if (result != null) {
        // ✅ Convert LiveLocationData to UserLiveLocationDataResponse
        _myLocation = result/*.toResponse(userName: _myUserName)*/;
        notifyListeners();
        print('📍 Location updated: $locationName');
      }
    } catch (e) {
      print('❌ Error updating location: $e');
    }
  }

  Future<void> refreshLocations() async {
    if (!_isTracking) {
      print('⚠️ Cannot refresh - not tracking');
      return;
    }
    
    try {
      _isLoading = true;
      notifyListeners();

      final locations = await LiveLocationService.getAllLocations();
      _allLocations = locations;

      if (_currentUserId != null) {
        final myLoc = _allLocations.firstWhere(
          (loc) => loc.userId == _currentUserId,
          orElse: () => UserLiveLocationDataResponse(
            userId: _currentUserId!,
            userName: _myUserName,
            locationName: _myLocation?.locationName ?? '',
            latitude: _myLocation?.latitude ?? 0.0,
            longitude: _myLocation?.longitude ?? 0.0,
            active: true,
          ),
        );
        if (myLoc.userId == _currentUserId) {
          _myLocation = myLoc;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error refreshing locations: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserLiveLocationDataResponse?> getLocationByUserId(String userId) async {
    try {
      return await LiveLocationService.getLocationByUserId(userId);
    } catch (e) {
      print('❌ Error getting location by user ID: $e');
      return null;
    }
  }

  Future<UserLiveLocationDataResponse?> getLocationByAdvocateId(String advocateId) async {
    try {
      return await LiveLocationService.getLocationByAdvocateId(advocateId);
    } catch (e) {
      print('❌ Error getting location by advocate ID: $e');
      return null;
    }
  }

  Future<List<UserLiveLocationDataResponse>> getLocationsByAdvocates(
    List<String> advocateIds,
  ) async {
    try {
      return await LiveLocationService.getLocationsByAdvocates(advocateIds);
    } catch (e) {
      print('❌ Error getting locations by advocates: $e');
      return [];
    }
  }

  void stopTracking() {
    print('⏹️ Stopping tracking');
    _isTracking = false;
    _heartbeatTimer?.cancel();
    _refreshTimer?.cancel();
    _isInitialized = false;
    notifyListeners();
    print('⏹️ Live Location Tracking Stopped');
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}