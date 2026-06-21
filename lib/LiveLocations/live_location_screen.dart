// lib/LiveLocations/live_location_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../LiveLocations/live_location_provider.dart';
import '../LiveLocations/live_location_model.dart';
import 'advocate_location_screen.dart';
import '../LiveLocations/nominatim_search_service.dart';
import 'live_navigation_screen.dart';

class LiveLocationScreen extends StatefulWidget {
  final String userId;
  final String? advocateId;
  final String userName;

  const LiveLocationScreen({
    super.key,
    required this.userId,
    this.advocateId,
    required this.userName,
  });

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  // Always initialized — never null, so .move() always works
  final MapController _mapController = MapController();

  LatLng? _cameraPosition;
  List<Marker> _markers = [];
  bool _isMapReady = false;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _isUpdatingMarkers = false;

  final TextEditingController _searchController = TextEditingController();
  LatLng? _searchedLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    try {
      final provider = context.read<LiveLocationProvider>();
      provider.stopTracking();
    } catch (e) {
      debugPrint('Warning: Error disposing: $e');
    }
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      final provider = context.read<LiveLocationProvider>();

      await provider.startTracking(
        userId: widget.userId,
        userName: widget.userName,
        advocateId: widget.advocateId,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _cameraPosition = provider.myLocation != null
              ? LatLng(
                  provider.myLocation!.latitude,
                  provider.myLocation!.longitude,
                )
              : const LatLng(23.8103, 90.4125);
          _isMapReady = true;
          _isInitialized = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateMarkersFromProvider();
        });
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _cameraPosition = const LatLng(23.8103, 90.4125);
          _isMapReady = true;
          _isInitialized = true;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _moveToSearchLocation(LatLng location, String name) {
    setState(() {
      _searchedLocation = location;
      _searchController.clear();
    });
    _mapController.move(location, 16);
    _showSnackBar('Moved to: $name', Colors.green);
  }

  Future<void> _navigateToUser(UserLiveLocationDataResponse user) async {
    try {
      final provider = context.read<LiveLocationProvider>();
      final currentLoc = provider.myLocation;

      if (currentLoc == null) {
        _showSnackBar('Your location not available', Colors.orange);
        return;
      }

      final distance = _calculateDistance(
        currentLoc.latitude,
        currentLoc.longitude,
        user.latitude,
        user.longitude,
      );

      _showNavigationOptions(user, distance);
    } catch (e) {
      debugPrint('Error navigating to user: $e');
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        (dLat / 2) * (dLat / 2) +
        (dLon / 2) *
            (dLon / 2) *
            math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * 3.141592653589793 / 180;

  void _showNavigationOptions(
    UserLiveLocationDataResponse user,
    double distance,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: user.isAdvocate ? Colors.purple : Colors.blue,
              child: Text(
                user.userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              user.isAdvocate ? 'Advocate' : 'User',
              style: TextStyle(
                color: user.isAdvocate ? Colors.purple : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Distance: ${distance.toStringAsFixed(2)} km',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Divider(),

            // FIX: All four ListTiles now have correct title: labels
            ListTile(
              leading: const Icon(Icons.directions, color: Colors.blue),

              subtitle: const Text('Open in Google Maps'),
              onTap: () {
                Navigator.pop(context);
                _openGoogleMaps(user.latitude, user.longitude);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.green),
              subtitle: const Text('Open in Apple Maps'),
              onTap: () {
                Navigator.pop(context);
                _openAppleMaps(user.latitude, user.longitude);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.orange),
              subtitle: const Text('Open in Waze'),
              onTap: () {
                Navigator.pop(context);
                _openWaze(user.latitude, user.longitude);
              },
            ),
            ListTile(
              leading: const Icon(Icons.public, color: Colors.purple),
              title: const Text('Open in Browser'),
              subtitle: const Text('Open Google Maps in browser'),
              onTap: () {
                Navigator.pop(context);
                _openInBrowser(user.latitude, user.longitude);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Add this method
  void _startLiveNavigation(UserLiveLocationDataResponse targetUser) {
    final provider = context.read<LiveLocationProvider>();
    final myLocation = provider.myLocation;

    if (myLocation == null) {
      _showSnackBar('Your location not available', Colors.orange);
      return;
    }

    // ✅ Pass required data to navigation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveNavigationScreen(
          userId: widget.userId,
          targetUserId: targetUser.userId,
          targetUserName: targetUser.userName,
          isTargetAdvocate: targetUser.isAdvocate,
          myLocation: myLocation,
          targetLocation: targetUser,
        ),
      ),
    );
  }


  void _openGoogleMaps(double lat, double lng) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    await _launchUrl(url);
  }

  void _openAppleMaps(double lat, double lng) async {
    final url = 'http://maps.apple.com/?daddr=$lat,$lng';
    await _launchUrl(url);
  }

  void _openWaze(double lat, double lng) async {
    final url = 'waze://?ll=$lat,$lng&navigate=yes';
    final fallbackUrl = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
    if (!await _launchUrl(url)) {
      await _launchUrl(fallbackUrl);
    }
  }

  void _openInBrowser(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    await _launchUrl(url);
  }

  Future<bool> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }

  void _updateMarkersFromProvider() {
    if (_isUpdatingMarkers || !mounted) return;
    _isUpdatingMarkers = true;

    try {
      final provider = context.read<LiveLocationProvider>();
      final List<Marker> newMarkers = [];

      if (provider.myLocation != null) {
        newMarkers.add(
          _createMarkerFromLiveLocation(provider.myLocation!, true),
        );
      }

      for (var location in provider.allLocations) {
        if (location.userId != provider.myLocation?.userId) {
          newMarkers.add(_createMarkerFromLiveLocation(location, false));
        }
      }

      if (_markers.length != newMarkers.length || _markers.isEmpty) {
        setState(() {
          _markers = newMarkers;
        });
      } else {
        _markers = newMarkers;
      }
    } catch (e) {
      debugPrint('Warning: Error updating markers: $e');
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  Marker _createMarkerFromLiveLocation(
    UserLiveLocationDataResponse location,
    bool isMyLocation,
  ) {
    return Marker(
      point: LatLng(location.latitude, location.longitude),
      width: 70,
      height: 90,
      child: GestureDetector(
        onTap: () {
          if (!isMyLocation) _showUserInfo(location);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: location.isAdvocate
                    ? Colors.purple
                    : (isMyLocation ? Colors.green : Colors.blue),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isMyLocation
                    ? Icons.my_location
                    : (location.isAdvocate ? Icons.gavel : Icons.person),
                color: Colors.white,
                size: 20,
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
                isMyLocation ? 'You' : location.userName,
                style: const TextStyle(color: Colors.white, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // FIX: was `Text('Live Location')` — missing `title:` named parameter
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              try {
                context.read<LiveLocationProvider>().refreshLocations();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateMarkersFromProvider();
                });
              } catch (e) {
                debugPrint('Warning: Error refreshing: $e');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showAdvocateList,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToMyLocation,
          ),
        ],
      ),
      body: Consumer<LiveLocationProvider>(
        builder: (context, provider, child) {
          if (_isLoading || !_isMapReady) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading location...'),
                ],
              ),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateMarkersFromProvider();
          });

          return Stack(
            children: [
              _buildMap(),
              if (provider.myLocation != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildLocationInfo(provider),
                ),
              Positioned(top: 16, right: 16, child: _buildStats(provider)),
            ],
          );
        },
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildMap() {
    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ClipRect(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _cameraPosition!,
              initialZoom: 15,
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
              MarkerLayer(markers: _markers),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchLocationDialog(
        onLocationSelected: (location, name) {
          _moveToSearchLocation(location, name);
        },
      ),
    );
  }

  Widget _buildLocationInfo(LiveLocationProvider provider) {
    final loc = provider.myLocation;
    if (loc == null) return const SizedBox.shrink();

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: loc.isAdvocate ? Colors.purple : Colors.blue,
                radius: 20,
                child: Icon(
                  loc.isAdvocate ? Icons.gavel : Icons.person,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      loc.locationName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: loc.active
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  loc.active ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: loc.active
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
              const SizedBox(width: 4),
              Text(
                '${loc.latitude.toStringAsFixed(6)}, '
                '${loc.longitude.toStringAsFixed(6)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Updated: ${_formatTime(loc.lastHeartbeat ?? DateTime.now())}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(LiveLocationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statRow(Colors.purple, 'Advocates', provider.onlineAdvocates.length),
          const SizedBox(height: 4),
          _statRow(Colors.blue, 'Users', provider.onlineUsers.length),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.refresh, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Total: ${provider.allLocations.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statRow(Color color, String label, int count) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showUserInfo(UserLiveLocationDataResponse location) {
    final provider = context.read<LiveLocationProvider>();
    double distance = 0;
    if (provider.myLocation != null) {
      distance = _calculateDistance(
        provider.myLocation!.latitude,
        provider.myLocation!.longitude,
        location.latitude,
        location.longitude,
      );
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: location.isAdvocate
                  ? Colors.purple
                  : Colors.blue,
              child: Text(
                location.userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              location.userName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              location.isAdvocate ? 'Advocate' : 'User',
              style: TextStyle(
                color: location.isAdvocate ? Colors.purple : Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(location.locationName)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  location.active ? Icons.circle : Icons.circle_outlined,
                  color: location.active ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  location.active ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: location.active ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                Text(
                  'Distance: ${distance.toStringAsFixed(2)} km',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // ✅ Live Navigation Button (In-App)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _startLiveNavigation(location);
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Live Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ✅ External Maps Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToUser(location);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('External'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvocateList() {
    try {
      final provider = context.read<LiveLocationProvider>();
      final advocates = provider.onlineAdvocates;

      if (advocates.isEmpty) {
        _showSnackBar('No advocates online', Colors.grey);
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Online Advocates',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: advocates.length,
                  itemBuilder: (context, index) {
                    final advocate = advocates[index];
                    double distance = 0;
                    final myLoc = provider.myLocation;
                    if (myLoc != null) {
                      distance = _calculateDistance(
                        myLoc.latitude,
                        myLoc.longitude,
                        advocate.latitude,
                        advocate.longitude,
                      );
                    }
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Text(
                          advocate.userName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      subtitle: Text(
                        '${advocate.locationName} • '
                        '${distance.toStringAsFixed(1)} km',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showUserInfo(advocate);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Warning: Error showing advocate list: $e');
    }
  }

  void _moveToMyLocation() {
    try {
      final provider = context.read<LiveLocationProvider>();
      if (provider.myLocation == null) return;

      _mapController.move(
        LatLng(provider.myLocation!.latitude, provider.myLocation!.longitude),
        16,
      );

      _showSnackBar('Moving to your location', Colors.blue);
    } catch (e) {
      debugPrint('Warning: Error moving to location: $e');
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dedicated StatefulWidget dialog for location search.
// Uses its own setState() so results rebuild without touching the parent tree.
// ─────────────────────────────────────────────────────────────────────────────
class _SearchLocationDialog extends StatefulWidget {
  final void Function(LatLng location, String name) onLocationSelected;

  const _SearchLocationDialog({required this.onLocationSelected});

  @override
  State<_SearchLocationDialog> createState() => _SearchLocationDialogState();
}
class _SearchLocationDialogState extends State<_SearchLocationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;
  List<LocationResult> _results = [];
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ✅ Debounced search for better UX
  Future<void> _search(String query) async {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    // ✅ Show loading immediately
    setState(() {
      _isSearching = true;
    });

    // ✅ Debounce: wait 300ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final raw = await NominatimSearchService.searchLocation(
          query.trim(),
          limit: 15, // ✅ More results for partial matches
        );

        if (!mounted) return;

        setState(() {
          _results = raw
              .map(
                (item) => LocationResult(
              name: item['name'] as String? ?? 'Unknown Location',
              displayName: item['display_name'] as String? ?? '',
              locationType: item['location_type'] as String? ?? 'Location',
              latitude: (item['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (item['longitude'] as num?)?.toDouble() ?? 0.0,
            ),
          )
              .toList();
          _isSearching = false;
        });

        print('✅ Found ${_results.length} results for: "$query"');

      } catch (e) {
        if (!mounted) return;
        print('❌ Search error: $e');
        setState(() {
          _isSearching = false;
          _results = [];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Search Location',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Search Input with clear button
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type partial location name...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _results = [];
                      _isSearching = false;
                    });
                  },
                )
                    : null,
              ),
              onChanged: _search,
            ),

            const SizedBox(height: 8),

            // ✅ Helper text for partial search
            if (_controller.text.isNotEmpty && !_isSearching && _results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No results found for "${_controller.text}"',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try typing a different name or check spelling',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // ✅ Loading indicator
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Searching...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

            // ✅ Results list with location type badge
            if (_results.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: Icon(
                          _getLocationIcon(result.locationType),
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        result.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        result.displayName.isNotEmpty
                            ? result.displayName
                            : result.locationType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          result.locationType,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onLocationSelected(
                          LatLng(result.latitude, result.longitude),
                          result.name,
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // ✅ Get icon based on location type
  IconData _getLocationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'city':
        return Icons.location_city;
      case 'town':
        return Icons.apartment;
      case 'village':
        return Icons.house;
      case 'suburb':
        return Icons.home_work;
      case 'neighborhood':
        return Icons.home;
      case 'landmark':
        return Icons.label_off_rounded;
      default:
        return Icons.location_on;
    }
  }
}

// ✅ Updated LocationResult with more fields
class LocationResult {
  final String name;
  final String displayName;
  final String locationType;
  final double latitude;
  final double longitude;

  const LocationResult({
    required this.name,
    this.displayName = '',
    this.locationType = 'Location',
    required this.latitude,
    required this.longitude,
  });
}
