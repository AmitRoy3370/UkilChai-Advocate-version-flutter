// lib/LiveLocations/advocate_location_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import '../LiveLocations/live_location_provider.dart';
import '../LiveLocations/location_service.dart';

class AdvocateLocationScreen extends StatefulWidget {
  final String advocateId;
  final String advocateName;

  const AdvocateLocationScreen({
    super.key,
    required this.advocateId,
    required this.advocateName,
  });

  @override
  State<AdvocateLocationScreen> createState() => _AdvocateLocationScreenState();
}

class _AdvocateLocationScreenState extends State<AdvocateLocationScreen> {
  MapController? _mapController;
  final LocationService _locationService = LocationService();
  LatLng? _cameraPosition;
  bool _isLoading = true;
  double _distance = 0;
  String? _locationName;
  double? _advocateLat;
  double? _advocateLng;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      final provider = Provider.of<LiveLocationProvider>(context, listen: false);
      await provider.refreshLocations();
      
      final advocate = provider.allLocations.firstWhere(
        (loc) => loc.id == widget.advocateId || loc.userId == widget.advocateId,
        orElse: () => throw Exception('Advocate not found'),
      );

      _advocateLat = advocate.latitude;
      _advocateLng = advocate.longitude;

      final currentPos = await _locationService.getCurrentLocation();
      
      if (currentPos != null) {
        _distance = _locationService.calculateDistance(
          currentPos.latitude,
          currentPos.longitude,
          advocate.latitude,
          advocate.longitude,
        );
        
        _locationName = await _locationService.getLocationName(
          advocate.latitude,
          advocate.longitude,
        );
      }

      setState(() {
        _cameraPosition = LatLng(advocate.latitude, advocate.longitude);
        _isLoading = false;
        
        // Add marker for advocate
        _markers = [
          Marker(
            point: LatLng(advocate.latitude, advocate.longitude),
            width: 60,
            height: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.gavel,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.advocateName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ];
        
        // Add current location marker
        if (currentPos != null) {
          _markers.add(
            Marker(
              point: LatLng(currentPos.latitude, currentPos.longitude),
              width: 50,
              height: 60,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
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
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });

    } catch (e) {
      print('❌ Error loading advocate location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ================= OPEN MAPS METHOD =================
  Future<void> _openMaps() async {
    if (_advocateLat == null || _advocateLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final currentPos = await _locationService.getCurrentLocation();
      
      String fromLat = currentPos?.latitude.toString() ?? '';
      String fromLng = currentPos?.longitude.toString() ?? '';
      
      final toLat = _advocateLat!.toString();
      final toLng = _advocateLng!.toString();
      
      String url;

      if (Platform.isAndroid) {
        url = 'https://www.google.com/maps/dir/?api=1'
            '&destination=$toLat,$toLng'
            '&travelmode=driving';
        if (fromLat.isNotEmpty && fromLng.isNotEmpty) {
          url += '&origin=$fromLat,$fromLng';
        }
      } else if (Platform.isIOS) {
        if (await canLaunchUrl(Uri.parse('comgooglemaps://'))) {
          url = 'comgooglemaps://?daddr=$toLat,$toLng';
          if (fromLat.isNotEmpty && fromLng.isNotEmpty) {
            url += '&saddr=$fromLat,$fromLng';
          }
          url += '&directionsmode=driving';
        } else {
          url = 'http://maps.apple.com/?daddr=$toLat,$toLng';
          if (fromLat.isNotEmpty && fromLng.isNotEmpty) {
            url += '&saddr=$fromLat,$fromLng';
          }
        }
      } else {
        url = 'https://www.google.com/maps/dir/?api=1'
            '&destination=$toLat,$toLng'
            '&travelmode=driving';
        if (fromLat.isNotEmpty && fromLng.isNotEmpty) {
          url += '&origin=$fromLat,$fromLng';
        }
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        Navigator.pop(context);
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        Navigator.pop(context);
        final fallbackUrl = 'https://www.google.com/maps/search/?api=1&query=$toLat,$toLng';
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch maps');
        }
      }

    } catch (e) {
      print('❌ Error opening maps: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening maps: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📍 ${widget.advocateName}'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'navigate') {
                _openMaps();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'navigate',
                child: Row(
                  children: [
                    Icon(Icons.directions),
                    SizedBox(width: 8),
                    Text('Navigate'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _cameraPosition!,
                    initialZoom: 16,
                    minZoom: 3,
                    maxZoom: 19,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: _markers,
                    ),
                  ],
                ),
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
                        Row(
                          children: [
                            const Icon(Icons.directions, color: Colors.purple),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Distance: ${_distance.toStringAsFixed(2)} km',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_locationName != null)
                                    Text(
                                      _locationName!,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openMaps,
                              icon: const Icon(Icons.navigation),
                              label: const Text('Navigate'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}