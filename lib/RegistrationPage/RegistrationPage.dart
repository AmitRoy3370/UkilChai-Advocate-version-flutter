import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as baseURL;
import 'package:file_picker/file_picker.dart';
import '../Utils/AdvocateSpeciality.dart';

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
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController licenseKeyController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController workingExperienceController =
      TextEditingController();

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
  File? cvFile;
  Uint8List? webCvBytes;
  String? cvFileName;

  final MapController mapController = MapController();

  Stream<Position>? _positionStream;

  List<String> degrees = [];
  List<String> workingExperiences = [];
  Set<AdvocateSpeciality> selectedSpecialities = {};

  Set<AdvocateSpeciality> selectedDistricts = {};

  final List<String> bangladeshDistricts = AdvocateSpeciality.values
      .map((e) => e.name)
      .toList();

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

  void showDistrictDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text("Select Specialist"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: bangladeshDistricts.map((district) {
                    return CheckboxListTile(
                      title: Text(district),
                      value: selectedDistricts.contains(
                        AdvocateSpecialityExt.fromApi(district),
                      ),
                      onChanged: (value) {
                        dialogSetState(() {
                          if (value == true) {
                            selectedDistricts.add(
                              AdvocateSpecialityExt.fromApi(district),
                            );
                          } else {
                            selectedDistricts.remove(district);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Pick CV PDF
  Future<void> pickCv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      if (kIsWeb) {
        webCvBytes = result.files.first.bytes;
        cvFileName = result.files.first.name;
      } else {
        cvFile = File(result.files.first.path!);
        cvFileName = result.files.first.name;
      }
      setState(() {});
    }
  }

  // Show speciality selection dialog
  void showSpecialityDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Specialities"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AdvocateSpeciality.values.map((e) {
                    return CheckboxListTile(
                      title: Text(e.label),
                      value: selectedSpecialities.contains(e),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val!) {
                            selectedSpecialities.add(e);
                          } else {
                            selectedSpecialities.remove(e);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add degree
  void addDegree() {
    if (degreeController.text.trim().isNotEmpty) {
      degrees.add(degreeController.text.trim());
      degreeController.clear();
      setState(() {});
    }
  }

  // Add working experience
  void addWorkingExperience() {
    if (workingExperienceController.text.trim().isNotEmpty) {
      workingExperiences.add(workingExperienceController.text.trim());
      workingExperienceController.clear();
      setState(() {});
    }
  }

  // Remove degree
  void removeDegree(String degree) {
    degrees.remove(degree);
    setState(() {});
  }

  // Remove working experience
  void removeWorkingExperience(String exp) {
    workingExperiences.remove(exp);
    setState(() {});
  }

  Future<void> _submitForm() async {
    try {
      final uri = Uri.parse("${baseURL.Urls().baseURL}auth/register");

      if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter userName")));
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

        // ---------------- ADVOCATE JOIN REQUEST ----------------

        final joinUri = Uri.parse(
          "${baseURL.Urls().baseURL}advocateJoinRequest",
        );

        var joinRequest = http.MultipartRequest("POST", joinUri);

        // 🔐 Authorization header
        joinRequest.headers["Authorization"] = "Bearer $token1";

        // -------- Required Fields --------
        joinRequest.fields["userId"] = userId;
        joinRequest.fields["experience"] =
            experienceController.text.trim().isEmpty
            ? "0"
            : experienceController.text.trim();
        joinRequest.fields["licenseKey"] = licenseKeyController.text.trim();

        // Convert Enum list to String list
        List<String> specialityList = selectedDistricts
            .map((e) => e.name)
            .toList();

        // Send JSON string
        joinRequest.fields["advocateSpeciality"] = jsonEncode(specialityList);

        joinRequest.fields["degrees"] = jsonEncode(degrees);
        joinRequest.fields["workingExperiences"] = jsonEncode(
          workingExperiences,
        );

        // -------- CV File Upload --------
        if (kIsWeb && webCvBytes != null) {
          joinRequest.files.add(
            http.MultipartFile.fromBytes(
              "file",
              webCvBytes!,
              filename: cvFileName ?? "cv.pdf",
              contentType: http.MediaType("application", "pdf"),
            ),
          );
        } else if (!kIsWeb && cvFile != null) {
          joinRequest.files.add(
            await http.MultipartFile.fromPath("file", cvFile!.path),
          );
        }

        // -------- Send Join Request --------
        final joinResponse = await joinRequest.send();
        final joinResponseBody = await joinResponse.stream.bytesToString();

        print("Join Status: ${joinResponse.statusCode}");
        print("Join Body: $joinResponseBody");

        if (joinResponse.statusCode == 200 || joinResponse.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Advocate Join Request Sent Successfully"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Join Request Failed: $joinResponseBody")),
          );
        }

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
              height: MediaQuery.of(context).size.height * 0.75,
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
                        physics: const AlwaysScrollableScrollPhysics(),
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
                                labelText: "userName",
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

                            TextField(
                              controller: experienceController,
                              decoration: const InputDecoration(
                                labelText: "Experience(year)",
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter
                                    .digitsOnly, // Only allows 0-9
                              ],
                            ),
                            TextField(
                              controller: licenseKeyController,
                              decoration: const InputDecoration(
                                labelText: "License Key",
                              ),
                            ),
                            // -------- Degree Input Section --------
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: degreeController,
                                    decoration: const InputDecoration(
                                      labelText: "Add Degree",
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: addDegree,
                                  child: const Text("Add"),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Show added degrees as chips
                            if (degrees.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: degrees.map((degree) {
                                  return Chip(
                                    label: Text(degree),
                                    deleteIcon: const Icon(Icons.close),
                                    onDeleted: () => removeDegree(degree),
                                  );
                                }).toList(),
                              ),

                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: workingExperienceController,
                                    decoration: const InputDecoration(
                                      labelText: "Add Working Experience",
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: addWorkingExperience,
                                  child: const Text("Add"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Show added working experiences as chips
                            if (workingExperiences.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: workingExperiences.map((
                                  workingExperience,
                                ) {
                                  return Chip(
                                    label: Text(workingExperience),
                                    deleteIcon: const Icon(Icons.close),
                                    onDeleted: () => removeWorkingExperience(
                                      workingExperience,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ElevatedButton(
                              onPressed: showDistrictDialog,
                              child: const Text("Select Specialist"),
                            ),

                            Wrap(
                              children: selectedDistricts
                                  .map(
                                    (d) => Chip(
                                      label: Text(d.apiValue),
                                      onDeleted: () {
                                        setState(() {
                                          selectedDistricts.remove(d);
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: pickCv,
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Upload CV (PDF)"),
                            ),
                            const SizedBox(height: 10),

                            if (cvFileName != null && cvFileName!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cvFileName!,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return AlertDialog(

                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          Text("Sending request..."),
                                        ],
                                      ),
                                    );
                                  },
                                );

                                try {
                                  await _submitForm();

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              child: const Text("Submit request"),
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
