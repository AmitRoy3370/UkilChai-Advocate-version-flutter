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
import '../LogInPage/LogIn.dart';
import '../AdvocatePages/AdvocateJoinRequestDetailsPage.dart';
import '../AdvocatePages/advocate_join_request_dto_model.dart';
import 'dart:async';

// ✅ Gender imports
import 'Gender.dart';
import 'UserGender.dart';
import 'UserGenderService.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController searchController = TextEditingController();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationTextController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController licenseKeyController = TextEditingController();

  // ✅ Updated Degree Controllers
  final TextEditingController degreeNameController = TextEditingController();
  final TextEditingController institutionController = TextEditingController();
  final TextEditingController degreeYearController = TextEditingController();

  final TextEditingController workingExperienceController =
      TextEditingController();

  // New Text Controllers for Working Experience & Additional Info
  final TextEditingController barAssociationController =
      TextEditingController();
  final TextEditingController barEnrolmentController = TextEditingController();
  final TextEditingController primaryPracticeController =
      TextEditingController();
  final TextEditingController chamberController = TextEditingController();
  final TextEditingController practiceYearsController = TextEditingController();
  final TextEditingController profExpController = TextEditingController();
  final TextEditingController practicingCoatController =
      TextEditingController();

  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController nidController = TextEditingController();
  final TextEditingController whatsAppController = TextEditingController();

  // New States for Documents
  List<PlatformFile> _documentFiles = [];
  DateTime? _enrollmentDate;
  DateTime? _dateOfBirth;

  bool _showPassword = false;

  // ✅ Gender state
  Gender? _selectedGender;

  // ✅ District selection
  String? _selectedDistrict;
  final List<String> _districts = [
    'Bagerhat', 'Bandarban', 'Barguna', 'Barisal', 'Bhola', 'Bogra',
    'Brahmanbaria', 'Chandpur', 'Chapai Nawabganj', 'Chittagong', 'Chuadanga',
    'Comilla', "Cox's Bazar", 'Dhaka', 'Dinajpur', 'Faridpur', 'Feni',
    'Gaibandha', 'Gazipur', 'Gopalganj', 'Habiganj', 'Jamalpur', 'Jessore',
    'Jhalokati', 'Jhenaidah', 'Joypurhat', 'Khagrachari', 'Khulna',
    'Kishoreganj', 'Kurigram', 'Kushtia', 'Lakshmipur', 'Lalmonirhat',
    'Madaripur', 'Magura', 'Manikganj', 'Meherpur', 'Moulvibazar',
    'Munshiganj', 'Mymensingh', 'Naogaon', 'Narail', 'Narayanganj',
    'Narsingdi', 'Natore', 'Netrokona', 'Nilphamari', 'Noakhali', 'Pabna',
    'Panchagarh', 'Patuakhali', 'Pirojpur', 'Rajbari', 'Rajshahi', 'Rangamati',
    'Rangpur', 'Satkhira', 'Shariatpur', 'Sherpur', 'Sirajganj', 'Sunamganj',
    'Sylhet', 'Tangail', 'Thakurgaon'
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

  bool _isSubmitting = false;

  final List<String> bangladeshDistricts = AdvocateSpeciality.values
      .map((e) => e.name)
      .toList();

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.listen(null).cancel();
    searchController.dispose();
    fullNameController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationTextController.dispose();
    experienceController.dispose();
    licenseKeyController.dispose();
    degreeNameController.dispose();
    institutionController.dispose();
    degreeYearController.dispose();
    workingExperienceController.dispose();
    barAssociationController.dispose();
    barEnrolmentController.dispose();
    primaryPracticeController.dispose();
    chamberController.dispose();
    practiceYearsController.dispose();
    profExpController.dispose();
    practicingCoatController.dispose();
    addressController.dispose();
    cityController.dispose();
    nidController.dispose();
    whatsAppController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // Safer location start with timeout so it won't hang forever
  Future<void> _startLocationUpdates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError("Please enable location service");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError("Location permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError("Location permission denied forever. Enable from settings.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
          timeLimit: Duration(seconds: 20),
        ),
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw TimeoutException(
            'Location request timed out. Using fallback position.'),
      );
      _updateDevicePosition(position);
    } catch (e) {
      debugPrint('Location error: $e');
      // Fallback to Dhaka center
      if (mounted && _devicePosition == null) {
        setState(() {
          _devicePosition = lat_lng.LatLng(23.8103, 90.4125);
          if (_selectedPosition == null) {
            _selectedPosition = _devicePosition;
            lattitude = 23.8103;
            longititude = 90.4125;
            locationTextController.text = 'Dhaka, Bangladesh';
          }
          _updateMarkers();
        });
      }
    }

    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );
      _positionStream!.listen(
        (Position position) => _updateDevicePosition(position),
        onError: (e) => debugPrint('Position stream error: $e'),
      );
    } catch (e) {
      debugPrint('Stream error: $e');
    }
  }

  Future<void> _updateDevicePosition(Position position) async {
    try {
      lat_lng.LatLng newPos =
          lat_lng.LatLng(position.latitude, position.longitude);
      String placeName = await getAddressFromLatLng(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => 'Lat: ${position.latitude}, Lng: ${position.longitude}',
      );

      if (!mounted) return;

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
        try {
          mapController.move(newPos, 15.0);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('updateDevicePosition error: $e');
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
    return 'Lat: $lat, Lng: $lng';
  }

  Future<void> searchPlace() async {
    String query = searchController.text.trim();
    if (query.isEmpty) return;

    lat_lng.LatLng? pos;
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
          if (mounted) {
            setState(() {
              _selectedPosition = pos;
              _selectedPlaceName = name;
              locationTextController.text = _selectedPlaceName!;
              _updateMarkers();
            });
            try {
              mapController.move(pos, 15.0);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Search error: $e');
    }

    if (pos == null) {
      _showError("No results found");
    }
  }

  Future<void> pickImage() async {
    try {
      XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null) {
        if (kIsWeb) {
          webImageBytes = await file.readAsBytes();
        } else {
          pickedImage = File(file.path);
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      _showError('Image pick failed: $e');
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
                "Select Speciality",
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: bangladeshDistricts.map((district) {
                    return CheckboxListTile(
                      title: Text(district),
                      value: selectedSpecialities.contains(
                        AdvocateSpecialityExt.fromApi(district),
                      ),
                      onChanged: (value) {
                        dialogSetState(() {
                          if (value == true) {
                            selectedSpecialities.add(
                              AdvocateSpecialityExt.fromApi(district),
                            );
                          } else {
                            selectedSpecialities.remove(
                              AdvocateSpecialityExt.fromApi(district),
                            );
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
                    Navigator.pop(context);
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

  Future<void> pickCv() async {
    try {
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
    } catch (e) {
      _showError('CV pick failed: $e');
    }
  }

  void addDegree() {
    final degreeName = degreeNameController.text.trim();
    final institution = institutionController.text.trim();
    final year = degreeYearController.text.trim();

    if (degreeName.isNotEmpty && institution.isNotEmpty) {
      String formattedDegree = "$degreeName from $institution";
      if (year.isNotEmpty) {
        formattedDegree += " in $year";
      }

      degrees.add(formattedDegree);

      degreeNameController.clear();
      institutionController.clear();
      degreeYearController.clear();

      setState(() {});
    } else {
      _showError("Please enter both Degree and Institution");
    }
  }

  void addWorkingExperience() {
    if (workingExperienceController.text.trim().isNotEmpty) {
      workingExperiences.add(workingExperienceController.text.trim());
      workingExperienceController.clear();
      setState(() {});
    }
  }

  void removeDegree(String degree) {
    degrees.remove(degree);
    setState(() {});
  }

  void removeWorkingExperience(String exp) {
    workingExperiences.remove(exp);
    setState(() {});
  }

  // Validates and returns the first missing field description, or null if OK
  String? _validateRequiredFields() {
    if (fullNameController.text.trim().isEmpty) return "Full Name is required";
    if (userNameController.text.trim().isEmpty) return "Username is required";
    if (emailController.text.trim().isEmpty) return "Email is required";
    if (phoneController.text.trim().isEmpty) return "Phone Number is required";
    if (passwordController.text.trim().isEmpty) return "Password is required";
    if (passwordController.text.trim().length < 6) {
      return "Password must be at least 6 characters";
    }
    if (_selectedGender == null) return "Please select your Gender";
    if (locationTextController.text.trim().isEmpty) {
      return "Please pick a location from the map";
    }
    if (_selectedDistrict == null) return "Please select your District";
    if (experienceController.text.trim().isEmpty) {
      return "Experience is required";
    }
    if (licenseKeyController.text.trim().isEmpty) {
      return "License Key is required";
    }
    if (selectedSpecialities.isEmpty) {
      return "Please select at least one Speciality";
    }
    return null;
  }

  Future<void> _submitForm() async {
    final validationError = _validateRequiredFields();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    // Guard against double submission
    if (_isSubmitting) return;
    _isSubmitting = true;

    try {
      // ---------- 1. REGISTER USER ----------
      final uri = Uri.parse("${baseURL.Urls().baseURL}auth/register");

      var request = http.MultipartRequest("POST", uri);
      request.fields["name"] = userNameController.text.trim();
      request.fields["password"] = passwordController.text.trim();
      request.fields["FullName"] = fullNameController.text.trim();
      request.fields["profileImageId"] = "profileImageId";

      if (kIsWeb && webImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', webImageBytes!,
            filename: 'profile.png',
            contentType: http.MediaType('image', 'png')));
      } else if (!kIsWeb && pickedImage != null) {
        request.files.add(
            await http.MultipartFile.fromPath("file", pickedImage!.path));
      }

      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('Registration request timed out'),
      );
      final responseBody = await response.stream.bytesToString();

      debugPrint("REGISTER STATUS: ${response.statusCode}");
      debugPrint("REGISTER BODY: $responseBody");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            "Registration failed (${response.statusCode}): $responseBody");
      }

      final decoded = jsonDecode(responseBody);
      final String? token = decoded['token'];
      final String? userId = decoded['id']?.toString() ??
          decoded['userId']?.toString();

      if (token == null || userId == null || token.isEmpty || userId.isEmpty) {
        throw Exception(
            "Registration response missing token or userId. Body: $responseBody");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("jwt_token", token);
      await prefs.setString("userId", userId);

      // ---------- 2. SAVE GENDER ----------
      final genderOk = await _saveUserGender(
        userId: userId,
        gender: _selectedGender!,
        token: token,
      );
      if (!genderOk) {
        debugPrint("⚠️ Gender save failed but continuing...");
      }

      // ---------- 3. SAVE CONTACT INFO ----------
      try {
        final contactRes = await http
            .post(
              Uri.parse(
                  "${baseURL.Urls().baseURL}user/contact-info/add?userId=$userId"),
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json"
              },
              body: jsonEncode({
                "userId": userId,
                "email": emailController.text.trim(),
                "phone": phoneController.text.trim()
              }),
            )
            .timeout(const Duration(seconds: 30));
        debugPrint("CONTACT STATUS: ${contactRes.statusCode}");
        debugPrint("CONTACT BODY: ${contactRes.body}");
      } catch (e) {
        debugPrint("Contact info error: $e");
      }

      // ---------- 4. SAVE LOCATION ----------
      try {
        final locRes = await http
            .post(
              Uri.parse("${baseURL.Urls().baseURL}userLocation/add"),
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json"
              },
              body: jsonEncode({
                "userId": userId,
                "locationName": locationTextController.text.trim(),
                "lattitude": lattitude,
                "longitude": longititude
              }),
            )
            .timeout(const Duration(seconds: 30));
        debugPrint("LOCATION STATUS: ${locRes.statusCode}");
        debugPrint("LOCATION BODY: ${locRes.body}");
      } catch (e) {
        debugPrint("Location error: $e");
      }

      // ---------- 5. CREATE JOIN REQUEST ----------
      final joinUri = Uri.parse("${baseURL.Urls().baseURL}advocateJoinRequest");
      var joinRequest = http.MultipartRequest("POST", joinUri);
      joinRequest.headers["Authorization"] = "Bearer $token";
      joinRequest.fields["userId"] = userId;
      joinRequest.fields["experience"] =
          experienceController.text.trim().isEmpty
              ? "0"
              : experienceController.text.trim();
      joinRequest.fields["licenseKey"] = licenseKeyController.text.trim();
      joinRequest.fields["district"] = _selectedDistrict ?? "Dhaka";
      joinRequest.fields["advocateSpeciality"] =
          jsonEncode(selectedSpecialities.map((e) => e.name).toList());
      joinRequest.fields["degrees"] = jsonEncode(degrees);
      joinRequest.fields["workingExperiences"] = jsonEncode(workingExperiences);

      if (kIsWeb && webCvBytes != null) {
        joinRequest.files.add(http.MultipartFile.fromBytes(
            "file", webCvBytes!,
            filename: cvFileName ?? "cv.pdf",
            contentType: http.MediaType("application", "pdf")));
      } else if (!kIsWeb && cvFile != null) {
        joinRequest.files
            .add(await http.MultipartFile.fromPath("file", cvFile!.path));
      }

      final joinResponse = await joinRequest.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('Join request timed out'),
      );
      final joinResBody = await joinResponse.stream.bytesToString();

      debugPrint("JOIN STATUS: ${joinResponse.statusCode}");
      debugPrint("JOIN BODY: $joinResBody");

      if (joinResponse.statusCode != 200 && joinResponse.statusCode != 201) {
        throw Exception(
            "Join request failed (${joinResponse.statusCode}): $joinResBody");
      }

      final joinData = jsonDecode(joinResBody);
      final String? joinRequestId =
          joinData['id']?.toString() ?? joinData['advocateId']?.toString();

      if (joinRequestId == null || joinRequestId.isEmpty) {
        throw Exception("Join request response missing id. Body: $joinResBody");
      }

      // ---------- 6. SAVE WORKING EXPERIENCE DETAILS ----------
      if (barAssociationController.text.isNotEmpty ||
          chamberController.text.isNotEmpty) {
        try {
          final weUri = Uri.parse(
              "${baseURL.Urls().baseURL}advocate-working-experience-in-join-request/add/$userId");
          final weRes = await http
              .post(
                weUri,
                headers: {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json"
                },
                body: jsonEncode({
                  "advocateId": joinRequestId,
                  "barAssociation": barAssociationController.text.trim(),
                  "barControllEnrolment": barEnrolmentController.text.trim(),
                  "enrollmentDate":
                      _enrollmentDate?.toUtc().toIso8601String(),
                  "practicingCoat": practicingCoatController.text.trim(),
                  "primaryPractice": primaryPracticeController.text.trim(),
                  "yearOfLegalPractice":
                      int.tryParse(practiceYearsController.text.trim()) ?? 0,
                  "currentChemberName": chamberController.text.trim(),
                  "professionalExperience":
                      int.tryParse(profExpController.text.trim()) ?? 0,
                }),
              )
              .timeout(const Duration(seconds: 30));
          debugPrint("WE STATUS: ${weRes.statusCode}");
          debugPrint("WE BODY: ${weRes.body}");
        } catch (e) {
          debugPrint("WE error: $e");
        }
      }

      // ---------- 7. SAVE ADDITIONAL INFO ----------
      if (nidController.text.isNotEmpty || addressController.text.isNotEmpty) {
        try {
          final aiUri = Uri.parse(
              "${baseURL.Urls().baseURL}advocate-additional-info-in-join-request/add/$userId");
          final aiRes = await http
              .post(
                aiUri,
                headers: {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json"
                },
                body: jsonEncode({
                  "advocateId": joinRequestId,
                  "parmanentAdress": addressController.text.trim(),
                  "cityOfUpozila": cityController.text.trim(),
                  "nidNumber": nidController.text.trim(),
                  "dateOfBirth": _dateOfBirth?.toUtc().toIso8601String(),
                  "whatsAppNumber": whatsAppController.text.trim(),
                }),
              )
              .timeout(const Duration(seconds: 30));
          debugPrint("AI STATUS: ${aiRes.statusCode}");
          debugPrint("AI BODY: ${aiRes.body}");
        } catch (e) {
          debugPrint("AI error: $e");
        }
      }

      // ---------- 8. UPLOAD DOCUMENTS ----------
      if (_documentFiles.isNotEmpty) {
        try {
          final docUri = Uri.parse(
              "${baseURL.Urls().baseURL}advocate-documents-in-join-request/add/$joinRequestId");
          var docRequest = http.MultipartRequest('POST', docUri);
          docRequest.headers['Authorization'] = 'Bearer $token';

          for (var file in _documentFiles) {
            if (kIsWeb && file.bytes != null) {
              docRequest.files.add(http.MultipartFile.fromBytes(
                  'files', file.bytes!,
                  filename: file.name));
            } else if (!kIsWeb && file.path != null) {
              docRequest.files.add(await http.MultipartFile.fromPath(
                  'files', file.path!,
                  filename: file.name));
            }
          }
          final docRes = await docRequest.send().timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException('Document upload timed out'),
          );
          final docBody = await docRes.stream.bytesToString();
          debugPrint("DOC STATUS: ${docRes.statusCode}");
          debugPrint("DOC BODY: $docBody");
        } catch (e) {
          debugPrint("Doc error: $e");
        }
      }

      // ---------- 9. FETCH FINAL DETAILS ----------
      final fetchUri = Uri.parse(
          "${baseURL.Urls().baseURL}advocateJoinRequest/user/$userId");
      final fetchRes = await http
          .get(fetchUri, headers: {"Authorization": "Bearer $token"})
          .timeout(const Duration(seconds: 30));

      debugPrint("FETCH STATUS: ${fetchRes.statusCode}");
      debugPrint("FETCH BODY: ${fetchRes.body}");

      if (fetchRes.statusCode != 200) {
        throw Exception(
            "Failed to load final details (${fetchRes.statusCode}): ${fetchRes.body}");
      }

      final dto = AdvocateJoinRequestDTO.fromJson(jsonDecode(fetchRes.body));

      await prefs.remove("jwt_token");
      await prefs.remove("userId");

      _dismissLoadingDialog();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AdvocateJoinRequestDetailsPage(request: dto)),
        );
      }
    } catch (e) {
      debugPrint("SUBMIT ERROR: $e");
      _dismissLoadingDialog();
      _showError('Registration failed: ${e.toString()}');
    } finally {
      _isSubmitting = false;
    }
  }

  /// Safely dismiss the loading dialog if it is showing
  void _dismissLoadingDialog() {
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<bool> _saveUserGender({
    required String userId,
    required Gender gender,
    required String token,
  }) async {
    // Try service first
    try {
      final service = UserGenderService();
      final created = await service.createUserGender(
        userId: userId,
        gender: gender,
      );
      if (kDebugMode) {
        print('✅ UserGender created: ${created.toString()}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ UserGenderService failed, trying raw http: $e');
      }
    }

    // Raw HTTP fallback
    try {
      final uri = Uri.parse(
        "${baseURL.Urls().baseURL}user-gender/create?userId=$userId",
      );
      final res = await http
          .post(
            uri,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "userId": userId,
              "gender": gender.name,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        print('📡 Raw gender create status: ${res.statusCode}');
        print('📡 Raw gender create body: ${res.body}');
      }

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e2) {
      if (kDebugMode) print('❌ Gender save failed completely: $e2');
      return false;
    }
  }

  Widget _buildOpenFormButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          showForm = true;
        });
      },
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
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Advocate Registration',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedForm() {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.0,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.gavel, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advocate Registration',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Fill up your information',
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
                  controller: scrollController,
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
                        controller: fullNameController,
                        label: "Full Name",
                        icon: Icons.badge_outlined,
                        hint: "Enter your full name",
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: userNameController,
                        label: "Username",
                        icon: Icons.person_outline,
                        hint: "Choose a unique username",
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        hint: "Enter your email address",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: phoneController,
                        label: "Phone Number",
                        icon: Icons.phone_outlined,
                        hint: "01XXXXXXXXX",
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      const SizedBox(height: 16),
                      _buildGenderDropdown(),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: locationTextController,
                        label: "Location",
                        icon: Icons.location_on_outlined,
                        hint: "Select from map",
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      _buildDistrictDropdown(),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: experienceController,
                        label: "Experience (Years)",
                        icon: Icons.work_outline,
                        hint: "How many years of experience",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: licenseKeyController,
                        label: "License Key",
                        icon: Icons.key,
                        hint: "Enter your license key",
                      ),
                      const SizedBox(height: 20),
                      _buildDegreeSection(),
                      const SizedBox(height: 20),
                      _buildWorkingExperienceSection(),
                      const SizedBox(height: 20),
                      _buildSpecialistSection(),
                      const SizedBox(height: 20),
                      _buildWorkingExperienceDetailsSection(),
                      const SizedBox(height: 20),
                      _buildAdditionalInfoSection(),
                      const SizedBox(height: 20),
                      _buildDocumentsSection(),
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
        );
      },
    );
  }

  Widget _buildWorkingExperienceDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Working Experience Details",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 12),
          _buildFormField(
              controller: barAssociationController,
              label: "Bar Association",
              icon: Icons.account_balance),
          const SizedBox(height: 12),
          _buildFormField(
              controller: barEnrolmentController,
              label: "Bar Council Enrolment",
              icon: Icons.badge),
          const SizedBox(height: 12),
          _buildDatePickerField(
            label: "Enrolment Date",
            selectedDate: _enrollmentDate,
            onPick: (d) => setState(() => _enrollmentDate = d),
          ),
          const SizedBox(height: 12),
          _buildFormField(
              controller: primaryPracticeController,
              label: "Primary Practice",
              icon: Icons.gavel),
          const SizedBox(height: 12),
          _buildFormField(
              controller: practicingCoatController,
              label: "Practicing Court",
              icon: Icons.account_balance_rounded),
          const SizedBox(height: 12),
          _buildFormField(
              controller: chamberController,
              label: "Current Chamber",
              icon: Icons.business),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildFormField(
                      controller: practiceYearsController,
                      label: "Legal Practice Years",
                      icon: Icons.timeline,
                      keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildFormField(
                      controller: profExpController,
                      label: "Professional Experience",
                      icon: Icons.timeline,
                      keyboardType: TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Additional Information",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 12),
          _buildFormField(
              controller: addressController,
              label: "Permanent Address",
              icon: Icons.home),
          const SizedBox(height: 12),
          _buildFormField(
              controller: cityController,
              label: "City / Upazila",
              icon: Icons.location_city),
          const SizedBox(height: 12),
          _buildFormField(
              controller: nidController,
              label: "NID Number",
              icon: Icons.credit_card,
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildDatePickerField(
            label: "Date of Birth",
            selectedDate: _dateOfBirth,
            onPick: (d) => setState(() => _dateOfBirth = d),
          ),
          const SizedBox(height: 12),
          _buildFormField(
              controller: whatsAppController,
              label: "WhatsApp Number",
              icon: Icons.chat,
              keyboardType: TextInputType.phone),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Other Documents",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue)),
        const SizedBox(height: 8),
        if (_documentFiles.isNotEmpty) ...[
          ..._documentFiles.asMap().entries.map((entry) {
            final idx = entry.key;
            final f = entry.value;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: Text(f.name, style: const TextStyle(fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => setState(() => _documentFiles.removeAt(idx)),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text("Upload Documents"),
          onPressed: _pickDocumentFiles,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            side: const BorderSide(color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? selectedDate,
    required void Function(DateTime) onPick,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime(1990),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate == null
                    ? label
                    : "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                style: TextStyle(
                  color:
                      selectedDate == null ? Colors.grey[600] : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocumentFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _documentFiles.addAll(
            result.files
                .where((f) => kIsWeb ? f.bytes != null : f.path != null),
          );
        });
      }
    } catch (e) {
      debugPrint('Pick docs error: $e');
      _showError('Failed to pick documents: $e');
    }
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gender",
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
          child: DropdownButtonFormField<Gender>(
            value: _selectedGender,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.wc, color: Colors.blue),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            hint: Text(
              "Select your gender",
              style: TextStyle(color: Colors.grey[400]),
            ),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
            iconSize: 30,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            items: Gender.values.map((Gender g) {
              return DropdownMenuItem<Gender>(
                value: g,
                child: Text(g.displayName),
              );
            }).toList(),
            onChanged: (Gender? newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "District",
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            hint: Text(
              "Select your district",
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
          labelText: "Password",
          labelStyle: const TextStyle(color: Colors.blue),
          hintText: "At least 6 characters",
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
          "Degrees",
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
              child: _buildFormField(
                controller: degreeNameController,
                label: "Degree (e.g. BSC)",
                icon: Icons.school,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFormField(
                controller: institutionController,
                label: "Institution (e.g. EWU)",
                icon: Icons.account_balance,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: degreeYearController,
                label: "Year (Optional)",
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 55,
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
                child: const Text("Add", style: TextStyle(color: Colors.white)),
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
          "Working Experience",
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
                    hintText: "Add working experience",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon:
                        const Icon(Icons.work_history, color: Colors.blue),
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
                child: const Text("Add", style: TextStyle(color: Colors.white)),
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
          "Specialist Areas",
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
                    selectedSpecialities.isEmpty
                        ? "Select Specialities"
                        : "${selectedSpecialities.length} Specialities Selected",
                    style: TextStyle(
                      color: selectedSpecialities.isEmpty
                          ? Colors.grey[600]
                          : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.blue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedSpecialities.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedSpecialities.map((d) {
              return Chip(
                label: Text(d.apiValue),
                onDeleted: () {
                  setState(() {
                    selectedSpecialities.remove(d);
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
          "CV (PDF)",
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
                    cvFileName ?? "Upload PDF File",
                    style: TextStyle(
                      color: cvFileName != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Browse",
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
          "Profile Image",
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
                        "Add Image",
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
        onPressed: _isSubmitting
            ? null
            : () async {
                FocusScope.of(context).unfocus();

                // Validate FIRST before showing loading
                final validationError = _validateRequiredFields();
                if (validationError != null) {
                  _showError(validationError);
                  return;
                }

                // Show non-dismissible loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Registering...",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Please wait",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );

                await _submitForm();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          disabledBackgroundColor: Colors.blue.withOpacity(0.5),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                "Complete Registration",
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
        title: const Text("Advocate Registration"),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: FlutterMap(
                  mapController: mapController,
                  options: const MapOptions(
                    initialCenter: lat_lng.LatLng(23.8103, 90.4125),
                    initialZoom: 13.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.advocatechai.app',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
              );
            },
          ),
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
                          hintText: "Search location...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
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
                  try {
                    mapController.move(_devicePosition!, 15.0);
                  } catch (_) {}
                } else {
                  _showError("Device location not available yet");
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          if (!showForm)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: _buildOpenFormButton(),
              ),
            ),
          if (showForm) _buildAnimatedForm(),
        ],
      ),
    );
  }
}