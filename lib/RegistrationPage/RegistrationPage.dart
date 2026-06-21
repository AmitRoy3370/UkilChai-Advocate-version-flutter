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

  // ✅ District selection
  String? _selectedDistrict;
  final List<String> _districts = [
    'Bagerhat',
    'Bandarban',
    'Barguna',
    'Barisal',
    'Bhola',
    'Bogra',
    'Brahmanbaria',
    'Chandpur',
    'Chapai Nawabganj',
    'Chittagong',
    'Chuadanga',
    'Comilla',
    "Cox's Bazar",
    'Dhaka',
    'Dinajpur',
    'Faridpur',
    'Feni',
    'Gaibandha',
    'Gazipur',
    'Gopalganj',
    'Habiganj',
    'Jamalpur',
    'Jessore',
    'Jhalokati',
    'Jhenaidah',
    'Joypurhat',
    'Khagrachari',
    'Khulna',
    'Kishoreganj',
    'Kurigram',
    'Kushtia',
    'Lakshmipur',
    'Lalmonirhat',
    'Madaripur',
    'Magura',
    'Manikganj',
    'Meherpur',
    'Moulvibazar',
    'Munshiganj',
    'Mymensingh',
    'Naogaon',
    'Narail',
    'Narayanganj',
    'Narsingdi',
    'Natore',
    'Netrokona',
    'Nilphamari',
    'Noakhali',
    'Pabna',
    'Panchagarh',
    'Patuakhali',
    'Pirojpur',
    'Rajbari',
    'Rajshahi',
    'Rangamati',
    'Rangpur',
    'Satkhira',
    'Shariatpur',
    'Sherpur',
    'Sirajganj',
    'Sunamganj',
    'Sylhet',
    'Tangail',
    'Thakurgaon'
  ];

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
            locationTextController.text = _selectedPlaceName!;
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Select Specialist",
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
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
                  child: const Text("Done", style: TextStyle(color: Colors.blue)),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Select Specialities",
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
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
                  child: const Text("Done", style: TextStyle(color: Colors.blue)),
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
      //final updateUri = Uri.parse("${baseURL.Urls().baseURL}user/update/${logInResponse.userId}");

      if (nameController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter userName")));
        return;
      } else if (passwordController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter password")));
        return;
      } else if (emailController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter email")));
        return;
      } else if (phoneController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter phone")));
        return;
      } else if (locationTextController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter location")));
        return;
      } else if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please select your district")));
        return;
      }

      String loginURL = "${baseURL.Urls().baseURL}auth/login";
      Uri uri1 = Uri.parse(loginURL);

      var logInResponse = await http.post(
        uri1,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userName": nameController.text, "password": passwordController.text}),
       );

      var request = (logInResponse.statusCode == 200 || logInResponse.statusCode == 201) ? http.MultipartRequest("PUT", Uri.parse("${baseURL.Urls().baseURL}user/update/${jsonDecode(logInResponse.body)['userId'].toString()}")) :  http.MultipartRequest("POST", uri);

      // -------- Text fields ----------
      request.fields["name"] = nameController.text.trim();
      request.fields["password"] = passwordController.text.trim();
      
      if((logInResponse.statusCode == 200 || logInResponse.statusCode == 201)) {

        request.headers["Authorization"] = "Bearer ${jsonDecode(logInResponse.body)['token'].toString()}";

      } 

      // optional (send only if backend allows)
      request.fields["profileImageId"] = "profileImageId";

      if (kDebugMode) {
        print("profileImageId :- ${request.fields["profileImageId"]}");
        print("district :- ${request.fields["district"]}");
      }

      // -------- File upload ----------
      if (kIsWeb && webImageBytes != null) {
        if (kIsWeb && webImageBytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              webImageBytes!,
              filename: '${nameController.text.trim()}.png',
              contentType: http.MediaType('image', 'png'),
            ),
          );
        }
      } else if (!kIsWeb && pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("file", pickedImage!.path),
        );
      }

      if (kDebugMode) {
        print("added file :- ${request.files.toString()}");
        print("request body :- ${request.fields}");
        print("request :- ${request.toString()}");
      }

      // -------- Send request ----------
      final response = await request.send();

      print(
        "response :- ${response.statusCode} and ${response.reasonPhrase} and ${response.request}",
      );

      final responseBody = await response.stream.bytesToString();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Registration status code :- ${response.statusCode} ")));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);

        // ✅ JWT token from backend
        final String token = (logInResponse.statusCode == 200 || logInResponse.statusCode == 201) ? jsonDecode(logInResponse.body)['token'].toString() : decoded["token"];
        final String userId = (logInResponse.statusCode == 200 || logInResponse.statusCode == 201) ? jsonDecode(logInResponse.body)['userId'].toString() : decoded['id'];

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
            "Authorization": "Bearer $_token",
            "Content-Type": "application/json",
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
            "Authorization": "Bearer $token1",
            "Content-Type": "application/json",
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
        joinRequest.fields["district"] = _selectedDistrict!; // ✅ District added

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
          
          // Clear form after successful submission
          setState(() {
            showForm = false;
          });
          
          nameController.clear();
          passwordController.clear();
          emailController.clear();
          phoneController.clear();
          locationTextController.clear();
          experienceController.clear();
          licenseKeyController.clear();
          degrees.clear();
          workingExperiences.clear();
          selectedDistricts.clear();
          _selectedDistrict = null;
          pickedImage = null;
          webImageBytes = null;
          cvFile = null;
          webCvBytes = null;
          cvFileName = null;
          
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
      ).showSnackBar(SnackBar(content: Text('${e.toString()}')));
    }
  }

  Widget _buildOpenFormButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          showForm = true;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(showForm ? 0.0 : 1.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1 + (value * 0.1),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gavel,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              const Text(
                'অ্যাডভোকেট রেজিস্ট্রেশন',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedForm() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      bottom: showForm ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.85,
      child: IgnorePointer(
        ignoring: !showForm,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: showForm ? 1 : 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 100),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 10) {
                      setState(() {
                        showForm = false;
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.blueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.gavel,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'অ্যাডভোকেট রেজিস্ট্রেশন',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'আপনার তথ্য পূরণ করুন',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => showForm = false),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      left: 20,
                      right: 20,
                      top: 20,
                    ),
                    child: Column(
                      children: [
                        _buildFormField(
                          controller: nameController,
                          label: "পূর্ণ নাম",
                          icon: Icons.person_outline,
                          hint: "আপনার পূর্ণ নাম লিখুন",
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: emailController,
                          label: "ইমেইল",
                          icon: Icons.email_outlined,
                          hint: "আপনার ইমেইল ঠিকানা",
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: phoneController,
                          label: "মোবাইল নম্বর",
                          icon: Icons.phone_outlined,
                          hint: "০১XXXXXXXXX",
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: locationTextController,
                          label: "লোকেশন",
                          icon: Icons.location_on_outlined,
                          hint: "মানচিত্র থেকে সিলেক্ট করুন",
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        
                        // ✅ District Dropdown Section
                        _buildDistrictDropdown(),
                        const SizedBox(height: 16),
                        
                        _buildFormField(
                          controller: experienceController,
                          label: "অভিজ্ঞতা (বছর)",
                          icon: Icons.work_outline,
                          hint: "কত বছর অভিজ্ঞতা",
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: licenseKeyController,
                          label: "লাইসেন্স কী",
                          icon: Icons.key,
                          hint: "আপনার লাইসেন্স কী লিখুন",
                        ),
                        const SizedBox(height: 20),
                        _buildDegreeSection(),
                        const SizedBox(height: 20),
                        _buildWorkingExperienceSection(),
                        const SizedBox(height: 20),
                        _buildSpecialistSection(),
                        const SizedBox(height: 20),
                        _buildCvPicker(),
                        const SizedBox(height: 20),
                        _buildImagePicker(),
                        const SizedBox(height: 30),
                        _buildSubmitButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ District Dropdown Widget
  Widget _buildDistrictDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "জেলা",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_city, color: Colors.blue),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            hint: Text(
              "আপনার জেলা নির্বাচন করুন",
              style: TextStyle(color: Colors.grey[400]),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
            iconSize: 30,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            items: _districts.map((String district) {
              return DropdownMenuItem<String>(
                value: district,
                child: Text(district),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedDistrict = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'দয়া করে একটি জেলা নির্বাচন করুন';
              }
              return null;
            },
          ),
        ),
        // ✅ Selected district display chip
        if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Chip(
              label: Text(_selectedDistrict!),
              backgroundColor: Colors.blue.withOpacity(0.1),
              labelStyle: const TextStyle(color: Colors.blue),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedDistrict = null;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blue),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: passwordController,
        obscureText: !_showPassword,
        decoration: InputDecoration(
          labelText: "পাসওয়ার্ড",
          labelStyle: const TextStyle(color: Colors.blue),
          hintText: "কমপক্ষে ৬ অক্ষর",
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.blue,
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDegreeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ডিগ্রী সমূহ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: degreeController,
                  decoration: InputDecoration(
                    hintText: "ডিগ্রী যোগ করুন",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.school, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: addDegree,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("যোগ করুন", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (degrees.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: degrees.map((degree) {
              return Chip(
                label: Text(degree),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => removeDegree(degree),
                backgroundColor: Colors.blue.withOpacity(0.1),
                deleteIconColor: Colors.blue,
                labelStyle: const TextStyle(color: Colors.blue),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildWorkingExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "কর্ম অভিজ্ঞতা",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: workingExperienceController,
                  decoration: InputDecoration(
                    hintText: "কর্ম অভিজ্ঞতা যোগ করুন",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.work_history, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: addWorkingExperience,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text("যোগ করুন", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (workingExperiences.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: workingExperiences.map((exp) {
              return Chip(
                label: Text(exp),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => removeWorkingExperience(exp),
                backgroundColor: Colors.blue.withOpacity(0.1),
                deleteIconColor: Colors.blue,
                labelStyle: const TextStyle(color: Colors.blue),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSpecialistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "স্পেশালিস্ট এলাকা",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: showDistrictDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDistricts.isEmpty
                        ? "স্পেশালিস্ট সিলেক্ট করুন"
                        : "${selectedDistricts.length} টি স্পেশালিস্ট সিলেক্ট করা হয়েছে",
                    style: TextStyle(
                      color: selectedDistricts.isEmpty ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.blue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedDistricts.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedDistricts.map((d) {
              return Chip(
                label: Text(d.apiValue),
                onDeleted: () {
                  setState(() {
                    selectedDistricts.remove(d);
                  });
                },
                backgroundColor: Colors.blue.withOpacity(0.1),
                deleteIconColor: Colors.blue,
                labelStyle: const TextStyle(color: Colors.blue),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCvPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "সিভি (PDF)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: pickCv,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cvFileName ?? "PDF ফাইল আপলোড করুন",
                    style: TextStyle(
                      color: cvFileName != null ? Colors.black87 : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "ব্রাউজ",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "প্রোফাইল ছবি",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: pickImage,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: pickedImage == null && webImageBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        "ছবি যোগ করুন",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  )
                : kIsWeb
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          webImageBytes!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          pickedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          FocusScope.of(context).unfocus();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "রেজিস্ট্রেশন হচ্ছে...",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "দয়া করে অপেক্ষা করুন",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );

          await _submitForm();

          if (mounted) {
            Navigator.pop(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
        child: const Text(
          "রেজিস্ট্রেশন সম্পন্ন করুন",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("অ্যাডভোকেট রেজিস্ট্রেশন"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Map
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: lat_lng.LatLng(23.8103, 90.4125),
                    initialZoom: 13.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.advocatechai.app',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
              );
            },
          ),

          // Gradient Overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.blue),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: "লোকেশন খুঁজুন...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        onSubmitted: (value) => searchPlace(),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: searchPlace,
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // My Location Button
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                if (_devicePosition != null) {
                  setState(() {
                    _selectedPosition = _devicePosition;
                    locationTextController.text = _selectedPlaceName ?? '';
                    _updateMarkers();
                  });
                  mapController.move(_devicePosition!, 15.0);
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // Open Form Button
          if (!showForm)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: _buildOpenFormButton(),
              ),
            ),

          // Animated Form
          _buildAnimatedForm(),
        ],
      ),
    );
  }
}