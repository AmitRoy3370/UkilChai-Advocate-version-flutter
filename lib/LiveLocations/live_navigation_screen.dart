// lib/LiveLocations/live_navigation_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../LiveLocations/live_location_model.dart';
import '../LiveLocations/live_location_service.dart';

class LiveNavigationScreen extends StatefulWidget {
  final String userId;
  final String targetUserId;
  final String targetUserName;
  final bool isTargetAdvocate;

  // ✅ Pass initial locations
  final UserLiveLocationDataResponse myLocation;
  final UserLiveLocationDataResponse targetLocation;

  const LiveNavigationScreen({
    super.key,
    required this.userId,
    required this.targetUserId,
    required this.targetUserName,
    required this.isTargetAdvocate,
    required this.myLocation,
    required this.targetLocation,
  });

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  bool _isLoading = false;
  bool _isNavigating = false;

  double _distance = 0;
  double _bearing = 0;
  String _eta = '--';
  String _lastUpdateTime = '--';

  Timer? _updateTimer;
  Timer? _myLocationTimer;

  // Target user's current location
  late UserLiveLocationDataResponse _targetLocation;

  // My current location
  late UserLiveLocationDataResponse _myLocation;

  // ✅ Debug counters
  int _updateCount = 0;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initialize with passed data
    _myLocation = widget.myLocation;
    _targetLocation = widget.targetLocation;

    print('📍 Navigation Started');
    print('📍 My Location: ${_myLocation.latitude}, ${_myLocation.longitude}');
    print('📍 Target Location: ${_targetLocation.latitude}, ${_targetLocation.longitude}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNavigation();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _updateTimer?.cancel();
    _myLocationTimer?.cancel();
    print('📍 Navigation Stopped');
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    setState(() {
      _isLoading = false;
      _isNavigating = true;
      _updateNavigationData();
      _updateMarkersAndRoute();
      _lastUpdateTime = DateTime.now().toLocal().toString().substring(0, 19);
    });

    // ✅ Start periodic updates for target user (every 3 seconds)
    _updateTimer = Timer.periodic(
      const Duration(seconds: 3),
          (timer) async {
        await _refreshTargetLocation();
      },
    );

    // ✅ Start periodic updates for my location (every 5 seconds)
    _myLocationTimer = Timer.periodic(
      const Duration(seconds: 5),
          (timer) async {
        await _refreshMyLocation();
      },
    );
  }

  // ✅ Refresh target user's location from API
  Future<void> _refreshTargetLocation() async {
    try {
      _updateCount++;
      print('🔄 [$_updateCount] Fetching target location for: ${widget.targetUserId}');

      // Get target user's location from API
      final targetLocation = await LiveLocationService.getLocationByUserId(
        widget.targetUserId,
      );

      if (targetLocation == null) {
        print('⚠️ [$_updateCount] Target user not found');
        _errorCount++;
        return;
      }

      print('📍 [$_updateCount] Target Location: ${targetLocation.latitude}, ${targetLocation.longitude}');

      // Check if location changed significantly (more than 5 meters)
      final latDiff = (targetLocation.latitude - _targetLocation.latitude).abs();
      final lngDiff = (targetLocation.longitude - _targetLocation.longitude).abs();

      print('📍 [$_updateCount] Diff: lat=$latDiff, lng=$lngDiff');

      if (latDiff > 0.00005 || lngDiff > 0.00005) {
        print('✅ [$_updateCount] Target MOVED! Updating...');
        print('   Old: (${_targetLocation.latitude}, ${_targetLocation.longitude})');
        print('   New: (${targetLocation.latitude}, ${targetLocation.longitude})');

        setState(() {
          _targetLocation = targetLocation;
          _updateNavigationData();
          _updateMarkersAndRoute();
          _lastUpdateTime = DateTime.now().toLocal().toString().substring(0, 19);
        });

        // ✅ Show notification
        _showSnackBar(
          '${widget.targetUserName} moved to new location',
          Colors.blue,
        );
      } else {
        // Update even if not moved (to keep timestamp fresh)
        setState(() {
          _lastUpdateTime = DateTime.now().toLocal().toString().substring(0, 19);
        });
      }
    } catch (e) {
      print('❌ [$_updateCount] Error refreshing target location: $e');
      _errorCount++;
    }
  }

  // ✅ Refresh my location from API
  Future<void> _refreshMyLocation() async {
    try {
      print('🔄 Fetching my location for: ${widget.userId}');

      // Get my location from API
      final myLocation = await LiveLocationService.getLocationByUserId(
        widget.userId,
      );

      if (myLocation == null) {
        print('⚠️ My location not found');
        return;
      }

      print('📍 My Location: ${myLocation.latitude}, ${myLocation.longitude}');

      // Check if location changed significantly
      final latDiff = (myLocation.latitude - _myLocation.latitude).abs();
      final lngDiff = (myLocation.longitude - _myLocation.longitude).abs();

      if (latDiff > 0.00005 || lngDiff > 0.00005) {
        print('✅ You MOVED! Updating...');
        print('   Old: (${_myLocation.latitude}, ${_myLocation.longitude})');
        print('   New: (${myLocation.latitude}, ${myLocation.longitude})');

        setState(() {
          _myLocation = myLocation;
          _updateNavigationData();
          _updateMarkersAndRoute();
          _lastUpdateTime = DateTime.now().toLocal().toString().substring(0, 19);
        });
      }
    } catch (e) {
      print('❌ Error refreshing my location: $e');
    }
  }

  void _updateNavigationData() {
    if (_myLocation == null || _targetLocation == null) return;

    // Calculate distance
    _distance = _calculateDistance(
      _myLocation.latitude,
      _myLocation.longitude,
      _targetLocation.latitude,
      _targetLocation.longitude,
    );

    // Calculate bearing
    _bearing = _calculateBearing(
      _myLocation.latitude,
      _myLocation.longitude,
      _targetLocation.latitude,
      _targetLocation.longitude,
    );

    // Calculate ETA (assuming average speed 5 km/h for walking)
    final etaMinutes = (_distance / 5) * 60;
    if (etaMinutes < 1) {
      _eta = '< 1 min';
    } else if (etaMinutes < 60) {
      _eta = '${etaMinutes.round()} min';
    } else {
      _eta = '${(etaMinutes / 60).round()} hr ${(etaMinutes % 60).round()} min';
    }

    print('📊 Updated: Distance=${_distance.toStringAsFixed(2)}km, Bearing=${_bearing.toStringAsFixed(0)}°');
  }

  void _updateMarkersAndRoute() {
    if (_myLocation == null || _targetLocation == null) return;

    print('🗺️ Updating markers and route...');

    final List<Marker> newMarkers = [];
    final List<Polyline> newPolylines = [];

    // ✅ My location marker with pulsing effect
    newMarkers.add(
      Marker(
        point: LatLng(_myLocation.latitude, _myLocation.longitude),
        width: 60,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final value = _pulseController.value;
                return Container(
                  width: 30 + (value * 20),
                  height: 30 + (value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.3 * (1 - value * 0.5)),
                  ),
                );
              },
            ),
            // Center dot
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 16,
              ),
            ),
            // Label
            Positioned(
              bottom: -20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // ✅ Target marker with pulsing effect
    newMarkers.add(
      Marker(
        point: LatLng(_targetLocation.latitude, _targetLocation.longitude),
        width: 60,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final value = _pulseController.value;
                return Container(
                  width: 30 + (value * 20),
                  height: 30 + (value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isTargetAdvocate
                        ? Colors.purple.withOpacity(0.3 * (1 - value * 0.5))
                        : Colors.red.withOpacity(0.3 * (1 - value * 0.5)),
                  ),
                );
              },
            ),
            // Center dot
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isTargetAdvocate ? Colors.purple : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                widget.isTargetAdvocate ? Icons.gavel : Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
            // Label
            Positioned(
              bottom: -20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.targetUserName,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // ✅ Route line between two points
    newPolylines.add(
      Polyline(
        points: [
          LatLng(_myLocation.latitude, _myLocation.longitude),
          LatLng(_targetLocation.latitude, _targetLocation.longitude),
        ],
        color: Colors.blue.withOpacity(0.6),
        strokeWidth: 4,
      ),
    );

    // Center map on the midpoint
    final midLat = (_myLocation.latitude + _targetLocation.latitude) / 2;
    final midLng = (_myLocation.longitude + _targetLocation.longitude) / 2;

    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
    });

    // Move camera to show both locations
    _mapController.move(
      LatLng(midLat, midLng),
      _getZoomLevel(),
    );
  }

  double _getZoomLevel() {
    if (_distance < 1) return 16;
    if (_distance < 5) return 14;
    if (_distance < 10) return 12;
    if (_distance < 50) return 10;
    return 8;
  }

  double _calculateDistance(
      double lat1, double lon1,
      double lat2, double lon2,
      ) {
    const double R = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = (dLat / 2) * (dLat / 2) +
        (dLon / 2) * (dLon / 2) *
            math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _calculateBearing(
      double lat1, double lon1,
      double lat2, double lon2,
      ) {
    final dLon = _toRadians(lon2 - lon1);
    final y = math.sin(dLon) * math.cos(_toRadians(lat2));
    final x = math.cos(_toRadians(lat1)) * math.sin(_toRadians(lat2)) -
        math.sin(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * math.cos(dLon);
    return (_toDegrees(math.atan2(y, x)) + 360) % 360;
  }

  double _toRadians(double degree) => degree * math.pi / 180;
  double _toDegrees(double radians) => radians * 180 / math.pi;

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _stopNavigation() {
    _updateTimer?.cancel();
    _myLocationTimer?.cancel();
    Navigator.pop(context);
  }

  // ✅ Manual force refresh
  Future<void> _forceRefresh() async {
    _showSnackBar('Refreshing locations...', Colors.green);
    await _refreshTargetLocation();
    await _refreshMyLocation();
    _showSnackBar('Locations updated!', Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Navigating to ${widget.targetUserName}',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: widget.isTargetAdvocate ? Colors.purple : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // ✅ Manual refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceRefresh,
            tooltip: 'Force Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _stopNavigation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading navigation...'),
          ],
        ),
      )
          : Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(23.8103, 90.4125),
              initialZoom: 14,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Debug info (top left)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔄 Updates: $_updateCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  /*Text(
                    '❌ Errors: $_errorCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),*/
                  Text(
                    '📍 Target: ${_targetLocation.latitude.toStringAsFixed(4)}, ${_targetLocation.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          // Navigation Info Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Distance and ETA
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: '${_distance.toStringAsFixed(2)} km',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.timer,
                          label: 'ETA (Walking)',
                          value: _eta,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bearing/Direction
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: _bearing * math.pi / 180,
                        child: Icon(
                          Icons.navigation,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_bearing.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getDirectionText(_bearing),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ✅ Last update time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🔄 Updated: $_lastUpdateTime',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Live status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live Tracking • Updates every 3s',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Stop navigation button
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _stopNavigation,
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getDirectionText(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'North';
    if (bearing >= 22.5 && bearing < 67.5) return 'North East';
    if (bearing >= 67.5 && bearing < 112.5) return 'East';
    if (bearing >= 112.5 && bearing < 157.5) return 'South East';
    if (bearing >= 157.5 && bearing < 202.5) return 'South';
    if (bearing >= 202.5 && bearing < 247.5) return 'South West';
    if (bearing >= 247.5 && bearing < 292.5) return 'West';
    if (bearing >= 292.5 && bearing < 337.5) return 'North West';
    return '--';
  }
}