import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as baseURL;

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationTextController = TextEditingController();

  bool _showPassword = false;

  lat_lng.LatLng? _devicePosition;
  lat_lng.LatLng? _selectedPosition;
  String? _selectedPlaceName;
  List<Marker> _markers = [];
  bool showForm = false;
  File? pickedImage;
  Uint8List? webImageBytes;
  double lattitude = 0.0;
  double longititude = 0.0;

  final MapController mapController = MapController();

  Stream<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location service")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied forever")),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    );
    _updateDevicePosition(position);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );

    _positionStream!.listen((Position position) {
      _updateDevicePosition(position);
    });
  }

  Future<void> _updateDevicePosition(Position position) async {
    lat_lng.LatLng newPos = lat_lng.LatLng(
      position.latitude,
      position.longitude,
    );
    String placeName = await getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _devicePosition = newPos;
      if (_selectedPosition == null) {
        _selectedPosition = newPos;
        _selectedPlaceName = placeName;
        lattitude = position.latitude;
        longititude = position.longitude;
        locationTextController.text = placeName;
      }
      _updateMarkers();
    });

    if (_selectedPosition == newPos) {
      mapController.move(newPos, 15.0);
    }
  }

  void _updateMarkers() {
    _markers = [];
    if (_devicePosition != null) {
      _markers.add(
        Marker(
          width: 80,
          height: 80,
          point: _devicePosition!,
          child: const Icon(Icons.my_location, color: Colors.red, size: 40),
        ),
      );
    }
    if (_selectedPosition != null && _selectedPosition != _devicePosition) {
      _markers.add(
        Marker(
          width: 80,
          height: 80,
          point: _selectedPosition!,
          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
        ),
      );
    }
  }

  // Unified Reverse Geocoding (using Nominatim for all platforms)
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AdvocateChaiApp/1.0 (your-email@example.com)'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? 'Unknown location';
      }
    } catch (e) {
      if (kDebugMode) print('Geocoding error: $e');
    }
    return 'Lat: $lat, Lng: $lng'; // Fallback
  }

  // Search for place (unified Nominatim for all platforms)
  Future<void> searchPlace() async {
    String query = searchController.text.trim();
    if (query.isEmpty) return;

    lat_lng.LatLng? pos;
    String locationText = query;

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'AdvocateChaiApp/1.0 (your-email@example.com)'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lng = double.parse(data[0]['lon']);
          lattitude = lat;
          longititude = lng;
          pos = lat_lng.LatLng(lat, lng);
          String name = data[0]['display_name'];
          setState(() {
            _selectedPosition = pos;
            _selectedPlaceName = name;
            locationTextController
                    .text = /*"Place: $name, Lat: $lat, Lng: $lng"*/
                _selectedPlaceName!;
            _updateMarkers();
          });
          mapController.move(pos, 15.0);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Search error: $e');
    }

    if (pos == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No results found")));
    }
  }

  // Pick image
  Future<void> pickImage() async {
    XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) {
      if (kIsWeb) {
        webImageBytes = await file.readAsBytes();
        pickedImage = File(file.path);
      } else {
        pickedImage = File(file.path);
      }
      setState(() {});
    }
  }

  Future<void> _submitForm() async {
    try {
      final uri = Uri.parse("${baseURL.Urls().baseURL}auth/register");

      if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter name")));
      } else if (passwordController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter password")));
      } else if (emailController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter email")));
      } else if (phoneController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter phone")));
      } else if (locationTextController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter location")));
      }

      var request = http.MultipartRequest("POST", uri);

      // -------- Text fields ----------
      request.fields["name"] = nameController.text.trim();
      request.fields["password"] = passwordController.text.trim();

      // optional (send only if backend allows)
      request.fields["profileImageId"] = "profileImageId";

      if (kDebugMode) {
        print("profileImageId :- ${request.fields["profileImageId"]}");
      }

      // -------- File upload ----------
      if (kIsWeb && webImageBytes != null) {
        if (kIsWeb && webImageBytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              webImageBytes!,
              filename: '${nameController.text.trim()}.png',
              contentType: http.MediaType('image', 'png'), // 🔥 VERY IMPORTANT
            ),
          );
        }

        /*request.files.add(
          await http.MultipartFile.fromPath("file", pickedImage!.path),
        );*/
      } else if (!kIsWeb && pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("file", pickedImage!.path),
        );
      }

      if (kDebugMode) {
        print("added file :- ${request.files.toString()}");
      }

      if (kDebugMode) {
        print("request body :- ${request.fields}");
      }

      if (kDebugMode) {
        print("request :- ${request.toString()}");
      }

      // -------- Send request ----------
      final response = await request.send();

      print(
        "response :- ${response.statusCode} and ${response.reasonPhrase} and ${response.request}",
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);

        // ✅ JWT token from backend
        final String token = decoded["token"];
        final String userId = decoded["userId"];

        print("received token :- $token");

        // -------- Save token (App + Web) ----------
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", token);
        await prefs.setString("userId", userId);

        final sharedPreferences = await SharedPreferences.getInstance();
        final _token = sharedPreferences.getString("jwt_token");

        if (_token == null || token.isEmpty) {
          print("No token found. User not logged in.");
          return;
        }

        String contactInfoUri =
            "${baseURL.Urls().baseURL}user/contact-info/add?userId=$userId";

        final url = Uri.parse(contactInfoUri);

        final responseForContactInfo = await http.post(
          url,
          headers: {
            "Authorization": "Bearer $_token", // Key: Use 'Bearer ' prefix
            "Content-Type":
                "application/json", // If JSON body; adjust as needed
          },
          body: jsonEncode({
            "userId": userId,
            "email": emailController.text.trim(),
            "phone": phoneController.text.trim(),
          }),
        );

        if (responseForContactInfo.statusCode == 200 ||
            responseForContactInfo.statusCode == 201) {
          if (kDebugMode) {
            print("Contact info added successfully");
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Contact info add successfully")),
          );
          if (kDebugMode) {
            print(
              "Contact info add successfully: ${responseForContactInfo.body}",
            );
          }
        } else {
          if (kDebugMode) {
            print("Contact info add failed");
          }
          if (kDebugMode) {
            print("Contact info add failed: ${responseForContactInfo.body}");
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(responseForContactInfo.body)));
        }

        final String locationUrl = "${baseURL.Urls().baseURL}userLocation/add";

        final loaction = Uri.parse(locationUrl);

        final sharedPreferences1 = await SharedPreferences.getInstance();
        final token1 = sharedPreferences1.getString("jwt_token");

        if (token1 == null || token.isEmpty) {
          print("No token found. User not logged in.");
          return;
        }

        print("latitude :- $lattitude longitude :- $longititude");

        final responseForContactInfo1 = await http.post(
          loaction,
          headers: {
            "Authorization": "Bearer $token1", // Key: Use 'Bearer ' prefix
            "Content-Type":
                "application/json", // If JSON body; adjust as needed
          },
          body: jsonEncode({
            "userId": userId,
            "locationName": locationTextController.text.trim(),
            "lattitude": lattitude,
            "longitude": longititude,
          }),
        );

        if (responseForContactInfo1.statusCode == 200 ||
            responseForContactInfo1.statusCode == 201) {
          print("Contact info added successfully");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location info add successfully")),
          );
          if (kDebugMode) {
            print(
              "Contact info add successfully: ${responseForContactInfo1.body}",
            );
          }
        } else {
          print("location info add failed ${responseForContactInfo1.body}");
          if (kDebugMode) {
            print("Location info add failed: ${responseForContactInfo1.body}");
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to add location...")));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful")),
        );

        if (kDebugMode) {
          print("JWT TOKEN => $token");
        }
      } else {
        if (kDebugMode) {
          print("Register failed: $responseBody");
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Registration failed")));
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registration with Map"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: lat_lng.LatLng(23.8103, 90.4125),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: "Search place...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: searchPlace,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: showForm ? 310 : 20,
            left: 10,
            child: Row(
              children: [
                const Text("Open Registration Form"),
                Switch(
                  value: showForm,
                  onChanged: (val) {
                    setState(() {
                      showForm = val;
                    });
                  },
                ),
              ],
            ),
          ),
          if (showForm)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                margin: const EdgeInsets.all(10),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 20,
                            ), // Space for close button
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: "Name",
                              ),
                            ),
                            TextField(
                              controller: passwordController,
                              obscureText: !_showPassword,
                              decoration: InputDecoration(
                                labelText: "Password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                ),
                              ),
                            ),

                            TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: "Email",
                              ),
                            ),
                            TextField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                labelText: "Phone",
                              ),
                            ),
                            TextField(
                              controller: locationTextController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: "Location Info",
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(border: Border.all()),
                                child:
                                    pickedImage == null && webImageBytes == null
                                    ? const Icon(Icons.camera_alt, size: 50)
                                    : kIsWeb
                                    ? Image.memory(
                                        webImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        pickedImage!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _submitForm,
                              child: const Text("Submit Registration"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            showForm = false;
                          });
                        },
                      ),
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
