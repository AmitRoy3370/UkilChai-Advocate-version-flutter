import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:advocatechaiadvocate/ProfilePage/SeeMyProfile.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as baseURL;
import '../Utils/BaseURL.dart' as BASEURL;
import '../Auth/AuthService.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;
import '../Utils/AdvocateSpeciality.dart';

import '../RegistrationPage/Gender.dart';
import '../RegistrationPage/UserGender.dart';
import '../RegistrationPage/UserGenderService.dart';
import '../AdvocatePages/advocate_working_experience_model.dart';
import '../AdvocatePages/advocate_working_experience_service.dart';
import '../AdvocatePages/advocate_documents_model.dart';
import '../AdvocatePages/advocate_documents_service.dart';
import '../AdvocatePages/advocate_additional_info_model.dart';
import '../AdvocatePages/advocate_additional_info_service.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController oldNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationTextController = TextEditingController();

  bool _showPassword = false, _showOldPassword = false;

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
    'Panchagarh', 'Patuakhali', 'Pirojpur', 'Rajbari', 'Rajshahi',
    'Rangamati', 'Rangpur', 'Satkhira', 'Shariatpur', 'Sherpur',
    'Sirajganj', 'Sunamganj', 'Sylhet', 'Tangail', 'Thakurgaon'
  ];

  lat_lng.LatLng? _devicePosition;
  lat_lng.LatLng? _selectedPosition;
  String? _selectedPlaceName;
  List<Marker> _markers = [];
  bool showForm = false;
  bool locationPresent = false;
  File? pickedImage;
  Uint8List? webImageBytes;
  double latitude = 0.0;
  double longitude = 0.0;

  File? cvFile;
  Uint8List? webCvBytes;
  String? cvFileName, selectedDistrict;

  String? advocateId;

  final TextEditingController experienceController = TextEditingController();
  final TextEditingController licenseKeyController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController workingExperienceController =
      TextEditingController();

  List<String> degrees = [];
  List<String> workingExperiences = [];
  Set<String> selectedSpecialities = {};
  List<AdvocateSpeciality> selectedDistricts = [];
  final List<String> bangladeshDistricts =
      AdvocateSpeciality.values.map((e) => e.name).toList();
  bool loading = true;
  bool isUpdating = false;

  final MapController mapController = MapController();

  Stream<Position>? _positionStream;

  final FocusNode _oldNameFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _oldPasswordFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _experienceFocus = FocusNode();
  final FocusNode _licenseFocus = FocusNode();
  final FocusNode _fullNameFocus = FocusNode();

  Gender? _selectedGender;
  UserGender? _existingUserGender;

  AdvocateWorkingExperience? _existingWorkingExperience;

  final TextEditingController _barAssociationController =
      TextEditingController();
  final TextEditingController _barControllEnrolmentController =
      TextEditingController();
  final TextEditingController _primaryPracticeController =
      TextEditingController();
  final TextEditingController _chamberController = TextEditingController();
  final TextEditingController _legalPracticeYearsController =
      TextEditingController();
  final TextEditingController _professionalExperienceController =
      TextEditingController();
  final TextEditingController _practicingCoatController =
      TextEditingController();
  DateTime? _enrollmentDate;

  AdvocateDocuments? _existingDocuments;
  List<PlatformFile> _newDocumentFiles = [];
  List<String> _existingDocumentAttachments = [];
  Set<String> _documentAttachmentsToDelete = {};

  AdvocateAdditionalInfo? _existingAdditionalInfo;

  final TextEditingController _permanentAddressController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _nidController = TextEditingController();
  final TextEditingController _whatsAppController = TextEditingController();
  DateTime? _dateOfBirth;

  bool _isLoadingDialogOpen = false;

  Future<File?> convertBytesToFile(
    Uint8List bytes, {
    required String extension,
  }) async {
    if (kIsWeb) {
      print('Conversion to File not supported on web. Use bytes directly.');
      return null;
    } else {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/profile.$extension';
      final file = File(tempPath);
      await file.writeAsBytes(bytes);
      return file;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ✅ RESILIENT PRELOAD — every sub-fetch is guarded individually
  //    so one failure never blocks the rest. `loading` is set to
  //    `false` ONLY after every sub-fetch has been attempted.
  // ══════════════════════════════════════════════════════════════
  Future<void> loadPreviousData() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('loadPreviousData: no token');
        return;
      }

      final userId = await AuthService.getUserId();
      if (userId == null || userId.isEmpty) {
        debugPrint('loadPreviousData: no userId');
        return;
      }

      // ── 1. User basics (name, full name, district) ─────────────
      try {
        final userRes = await http.get(
          Uri.parse("${baseURL.Urls().baseURL}user/search?userId=$userId"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ).timeout(const Duration(seconds: 15));

        if (userRes.statusCode == 200) {
          final data = jsonDecode(userRes.body);
          if (mounted) {
            setState(() {
              oldNameController.text = (data["name"] ?? '').toString();
              nameController.text = (data["name"] ?? '').toString();
              fullNameController.text =
                  (data["FullName"] ?? data["fullName"] ?? '').toString();
              final userDistrict =
                  (data["district"] ?? '').toString().trim();
              if (userDistrict.isNotEmpty && _selectedDistrict == null) {
                _selectedDistrict = userDistrict;
              }
            });
          }

          // ── 2. Profile image (guarded) ────────────────────────
          final profileImageId = data["profileImageId"];
          if (profileImageId != null &&
              profileImageId.toString().isNotEmpty) {
            try {
              final profileImageRes = await http.get(
                Uri.parse(
                    "${baseURL.Urls().baseURL}user/download/$profileImageId"),
                headers: {
                  "Accept": "image/*,application/octet-stream",
                  "Authorization": "Bearer $token",
                },
              ).timeout(const Duration(seconds: 15));

              if (profileImageRes.statusCode == 200 &&
                  profileImageRes.bodyBytes.isNotEmpty) {
                final bytes = profileImageRes.bodyBytes;
                final isJpeg = bytes.length > 4 &&
                    bytes[0] == 0xFF &&
                    bytes[1] == 0xD8;
                final isPng = bytes.length > 4 &&
                    bytes[0] == 0x89 &&
                    bytes[1] == 0x50 &&
                    bytes[2] == 0x4E &&
                    bytes[3] == 0x47;
                if ((isJpeg || isPng) && mounted) {
                  final extension = isJpeg ? 'jpg' : 'png';
                  final file =
                      await convertBytesToFile(bytes, extension: extension);
                  if (mounted) {
                    setState(() {
                      webImageBytes = bytes;
                      pickedImage = file;
                    });
                  }
                }
              }
            } catch (e) {
              debugPrint('profile image load failed (non-fatal): $e');
            }
          }
        }
      } catch (e) {
        debugPrint('user/search failed (non-fatal): $e');
      }

      // ── 3. Location ──────────────────────────────────────────
      try {
        final locationRes = await http.get(
          Uri.parse(
              "${baseURL.Urls().baseURL}userLocation/findByUserId/$userId"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ).timeout(const Duration(seconds: 15));

        if (locationRes.statusCode == 200) {
          final d = jsonDecode(locationRes.body);
          if (mounted) {
            setState(() {
              locationPresent = true;
              locationTextController.text =
                  (d["locationName"] ?? '').toString();
              latitude = (d["lattitude"] ?? 0.0) is num
                  ? (d["lattitude"] as num).toDouble()
                  : 0.0;
              longitude = (d["longitude"] ?? 0.0) is num
                  ? (d["longitude"] as num).toDouble()
                  : 0.0;
              _selectedPosition = lat_lng.LatLng(latitude, longitude);
            });
          }
        }
      } catch (e) {
        debugPrint('userLocation failed (non-fatal): $e');
      }

      // ── 4. Contact info (email, phone) ───────────────────────
      try {
        final contactRes = await http.get(
          Uri.parse(
              "${baseURL.Urls().baseURL}user/contact-info/user?userId=$userId"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ).timeout(const Duration(seconds: 15));

        if (contactRes.statusCode == 200) {
          final d = jsonDecode(contactRes.body);
          if (mounted) {
            setState(() {
              emailController.text = (d["email"] ?? '').toString();
              phoneController.text = (d["phone"] ?? '').toString();
            });
          }
        }
      } catch (e) {
        debugPrint('contact-info failed (non-fatal): $e');
      }

      // ── 5. Advocate record (identity + fields) ───────────────
      String? resolvedAdvocateId;
      try {
        final advocateRes = await http.get(
          Uri.parse("${baseURL.Urls().baseURL}advocate/findByUser/$userId"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ).timeout(const Duration(seconds: 15));

        if (advocateRes.statusCode == 200) {
          final d = jsonDecode(advocateRes.body);
          resolvedAdvocateId = d["id"]?.toString();

          if (mounted) {
            setState(() {
              advocateId = resolvedAdvocateId;
              experienceController.text =
                  (d["experience"] ?? '').toString();
              licenseKeyController.text =
                  (d["licenseKey"] ?? '').toString();
              degrees = List<String>.from(d["degrees"] ?? const []);
              workingExperiences =
                  List<String>.from(d["workingExperiences"] ?? const []);
              selectedSpecialities =
                  Set<String>.from(d["advocateSpeciality"] ?? const []);

              final advDistrict =
                  (d["district"] ?? '').toString().trim();
              if (advDistrict.isNotEmpty) {
                _selectedDistrict = advDistrict;
                selectedDistrict = advDistrict;
              }
            });
          }
        }
      } catch (e) {
        debugPrint('advocate/findByUser failed (non-fatal): $e');
      }

      // ── 6. CV (FIXED) — always fetch by the LOGGED-IN userId.
      //    The backend endpoint is advocate/cv/{userId}, which is the
      //    same id used by downloadCv(). Previously we used the
      //    advocate's `userId` field (sometimes null) — that's why
      //    the CV never appeared. Now we try the logged-in userId
      //    first, and fall back to the advocate's userId only if the
      //    first attempt fails.
      await _loadCvBytes(userId, token, fallbackUserId: null);

      // ── 7. Gender (guarded) ──────────────────────────────────
      await _loadGender(userId);

      // ── 8. Dependent sections (only if advocateId resolved) ──
      if (resolvedAdvocateId != null && resolvedAdvocateId.isNotEmpty) {
        await _loadWorkingExperience(resolvedAdvocateId);
        await _loadDocuments(resolvedAdvocateId);
        await _loadAdditionalInfo(resolvedAdvocateId);
      }
    } catch (e) {
      debugPrint('⚠️ loadPreviousData failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// ✅ NEW HELPER — loads the CV by the given `userId` (the logged-in
  /// one). If a `fallbackUserId` is passed and the first attempt fails,
  /// we try again with the fallback (usually the advocate record's
  /// `userId`, in case the backend keys CVs by that instead).
  Future<void> _loadCvBytes(
    String userId,
    String token, {
    String? fallbackUserId,
  }) async {
    Future<bool> tryFetch(String id) async {
      if (id.isEmpty) return false;
      try {
        final res = await http.get(
          Uri.parse("${baseURL.Urls().baseURL}advocate/cv/$id"),
          headers: {"Authorization": "Bearer $token"},
        ).timeout(const Duration(seconds: 15));

        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          if (mounted) {
            setState(() {
              webCvBytes = res.bodyBytes;
              cvFileName = "previous_cv.pdf";
            });
          }
          return true;
        }
        debugPrint('cv fetch ($id) → ${res.statusCode}');
      } catch (e) {
        debugPrint('cv fetch ($id) failed: $e');
      }
      return false;
    }

    final first = await tryFetch(userId);
    if (first) return;

    if (fallbackUserId != null && fallbackUserId != userId) {
      await tryFetch(fallbackUserId);
    }
  }

  Future<void> _loadGender(String userId) async {
    try {
      final service = UserGenderService();
      final gender = await service
          .findByUserId(userId)
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _existingUserGender = gender;
          _selectedGender = gender.gender;
        });
      }
    } catch (e) {
      debugPrint('ℹ️ No existing gender: $e');
    }
  }

  Future<void> _loadWorkingExperience(String advocateId) async {
    try {
      final we = await AdvocateWorkingExperienceService.findByAdvocateId(
              advocateId)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _existingWorkingExperience = we;
        _barAssociationController.text = we.barAssociation ?? '';
        _barControllEnrolmentController.text =
            we.barControllEnrolment ?? '';
        _primaryPracticeController.text = we.primaryPractice ?? '';
        _chamberController.text = we.currentChemberName;
        _legalPracticeYearsController.text =
            we.yearOfLegalPractice.toString();
        _professionalExperienceController.text =
            we.professionalExperience.toString();
        _practicingCoatController.text = we.practicingCoat ?? '';
        if (we.enrollmentDate != null && we.enrollmentDate!.isNotEmpty) {
          _enrollmentDate = DateTime.tryParse(we.enrollmentDate!);
        }
      });
    } catch (e) {
      debugPrint('ℹ️ No existing working experience: $e');
    }
  }

  Future<void> _loadDocuments(String advocateId) async {
    try {
      final docs = await AdvocateDocumentsService.findByAdvocateId(advocateId)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _existingDocuments = docs;
        _existingDocumentAttachments = List.from(docs.attachments);
      });
    } catch (e) {
      debugPrint('ℹ️ No existing documents: $e');
    }
  }

  Future<void> _loadAdditionalInfo(String resolvedAdvocateId) async {
    try {
      final info = await AdvocateAdditionalInfoService.findByAdvocateId(
              resolvedAdvocateId)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _existingAdditionalInfo = info;
        _permanentAddressController.text = info.parmanentAdress ?? '';
        _cityController.text = info.cityOfUpozila ?? '';
        _nidController.text = info.nidNumber ?? '';
        _whatsAppController.text = info.whatsAppNumber ?? '';
        if (info.dateOfBirth != null && info.dateOfBirth!.isNotEmpty) {
          _dateOfBirth = DateTime.tryParse(info.dateOfBirth!);
        }
      });
    } catch (e) {
      debugPrint('ℹ️ No existing additional info: $e');
    }
  }

  void downloadPdfWeb(List<int> bytes) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "file.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void showDistrictDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                "Select Specialist",
                style: TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: bangladeshDistricts.map((district) {
                    return CheckboxListTile(
                      title: Text(district),
                      value: selectedDistricts.contains(district),
                      onChanged: (value) {
                        dialogSetState(() {
                          if (value == true) {
                            selectedDistricts
                                .add(AdvocateSpecialityExt.fromApi(district));
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
                  child: const Text("Done",
                      style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showSpecialityDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                "Select Specialities",
                style: TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AdvocateSpeciality.values.map((e) {
                    return CheckboxListTile(
                      title: Text(e.label),
                      value: selectedSpecialities.contains(e.apiValue),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val!) {
                            selectedSpecialities.add(e.apiValue);
                          } else {
                            selectedSpecialities.remove(e.apiValue);
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
                  child: const Text("Done",
                      style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void addDegree() {
    if (degreeController.text.trim().isNotEmpty) {
      degrees.add(degreeController.text.trim());
      degreeController.clear();
      setState(() {});
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

  @override
  void initState() {
    super.initState();
    loadPreviousData();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    searchController.dispose();
    fullNameController.dispose();
    nameController.dispose();
    oldNameController.dispose();
    passwordController.dispose();
    oldPasswordController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationTextController.dispose();
    experienceController.dispose();
    licenseKeyController.dispose();
    degreeController.dispose();
    workingExperienceController.dispose();
    _oldNameFocus.dispose();
    _nameFocus.dispose();
    _oldPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _experienceFocus.dispose();
    _licenseFocus.dispose();
    _fullNameFocus.dispose();

    _barAssociationController.dispose();
    _barControllEnrolmentController.dispose();
    _primaryPracticeController.dispose();
    _chamberController.dispose();
    _legalPracticeYearsController.dispose();
    _professionalExperienceController.dispose();
    _practicingCoatController.dispose();
    _permanentAddressController.dispose();
    _cityController.dispose();
    _nidController.dispose();
    _whatsAppController.dispose();
    super.dispose();
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location service")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
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
      locationPresent ? latitude : position.latitude,
      locationPresent ? longitude : position.longitude,
    );
    String placeName = await getAddressFromLatLng(
      locationPresent ? latitude : position.latitude,
      locationPresent ? longitude : position.longitude,
    );

    if (!mounted) return;
    setState(() {
      _devicePosition = newPos;
      if (_selectedPosition == null) {
        _selectedPosition = newPos;
        _selectedPlaceName = placeName;
        latitude = position.latitude;
        longitude = position.longitude;
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

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AdvocateChaiApp/1.0 (your-email@example.com)'},
      ).timeout(const Duration(seconds: 10));
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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() => locationPresent = false);
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lng = double.parse(data[0]['lon']);

          setState(() {
            latitude = lat;
            longitude = lng;
          });

          pos = lat_lng.LatLng(lat, lng);
          String name = data[0]['display_name'];
          _selectedPosition = pos;
          _selectedPlaceName = name;
          locationTextController.text = _selectedPlaceName!;
          _updateMarkers();
          mapController.move(pos, 15.0);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Search error: $e');
    }

    if (pos == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No results found")));
    }
  }

  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                XFile? file = await ImagePicker()
                    .pickImage(source: ImageSource.gallery);
                if (file != null) {
                  if (kIsWeb) {
                    webImageBytes = await file.readAsBytes();
                  } else {
                    pickedImage = File(file.path);
                  }
                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                XFile? file = await ImagePicker()
                    .pickImage(source: ImageSource.camera);
                if (file != null) {
                  if (kIsWeb) {
                    webImageBytes = await file.readAsBytes();
                  } else {
                    pickedImage = File(file.path);
                  }
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _pickDocumentFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _newDocumentFiles.addAll(
            result.files.where((f) => kIsWeb ? f.bytes != null : f.path != null),
          );
        });
      }
    } catch (e) {
      debugPrint('Pick docs error: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() => isUpdating = true);

    try {
      final logInUri = Uri.parse("${baseURL.Urls().baseURL}auth/login");
      final logInResponse = await http
          .post(
            logInUri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "userName": oldNameController.text.trim(),
              "password": oldPasswordController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (logInResponse.statusCode != 200) {
        _showSnackBar("Old password is incorrect", Colors.red);
        return;
      }

      final decoded = jsonDecode(logInResponse.body);
      String? token = decoded["token"];
      String? userId = decoded["userId"];

      if (token == null || userId == null) {
        _showSnackBar("Login response invalid", Colors.red);
        return;
      }

      final uri = Uri.parse("${baseURL.Urls().baseURL}user/update/$userId");
      var request = http.MultipartRequest("PUT", uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields["name"] = nameController.text.trim();
      request.fields["password"] = passwordController.text.trim();
      if (fullNameController.text.trim().isNotEmpty) {
        request.fields["fullName"] = fullNameController.text.trim();
      }

      if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
        request.fields["district"] = _selectedDistrict!;
      }

      try {
        final imageFindingUri = Uri.parse(
            "${baseURL.Urls().baseURL}user/search?userId=$userId");
        final imageFindingResponse = await http.get(
          imageFindingUri,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        ).timeout(const Duration(seconds: 15));

        if (imageFindingResponse.statusCode == 200) {
          final imageFindingResponseData =
              jsonDecode(imageFindingResponse.body);
          String? profileImageId =
              imageFindingResponseData["profileImageId"];
          if (profileImageId != null && profileImageId.isNotEmpty) {
            request.fields["profileImageId"] = profileImageId;
          }
        }
      } catch (e) {
        debugPrint('Image-id fetch failed (non-fatal): $e');
      }

      if (kIsWeb && webImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webImageBytes!,
            filename: '${nameController.text.trim()}.png',
            contentType: http.MediaType('image', 'png'),
          ),
        );
      } else if (!kIsWeb && pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("file", pickedImage!.path),
        );
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        _showSnackBar("Update failed: ${response.statusCode}", Colors.red);
        return;
      }

      final sharedPreferences = await SharedPreferences.getInstance();
      final String? tokenFromPrefs = sharedPreferences.getString("jwt_token");

      AuthService.saveToken(token);
      AuthService.saveUserId(userId);

      await _updateContactInfo(userId, tokenFromPrefs ?? token);
      await _updateLocationInfo(userId, tokenFromPrefs ?? token);

      if (advocateId != null) {
        await _updateAdvocateInfo(userId, tokenFromPrefs ?? token);
        await _updateGender(userId, tokenFromPrefs ?? token);
        await _updateWorkingExperience(
            advocateId!, userId, tokenFromPrefs ?? token);
        await _updateDocuments(advocateId!, userId, tokenFromPrefs ?? token);
        await _updateAdditionalInfo(
            advocateId!, userId, tokenFromPrefs ?? token);
      }

      _showSnackBar("Profile updated successfully! 🎉", Colors.green);

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on TimeoutException catch (_) {
      _showSnackBar(
          "Request timed out. Please check your connection.", Colors.red);
    } catch (e) {
      _showSnackBar("An error occurred: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  bool _validateForm() {
    if (fullNameController.text.isEmpty) {
      _showSnackBar("Please enter your full name", Colors.orange);
      return false;
    }
    if (nameController.text.isEmpty) {
      _showSnackBar("Please enter a new username", Colors.orange);
      return false;
    }
    if (oldPasswordController.text.isEmpty) {
      _showSnackBar("Please enter your old password", Colors.orange);
      return false;
    }
    if (passwordController.text.isEmpty) {
      _showSnackBar("Please enter a new password", Colors.orange);
      return false;
    }
    if (locationTextController.text.isEmpty) {
      _showSnackBar("Please select a location", Colors.orange);
      return false;
    }
    if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
      _showSnackBar("Please select a district", Colors.orange);
      return false;
    }
    return true;
  }

  Future<void> _updateContactInfo(String userId, String token) async {
    try {
      final contactInfoUri = Uri.parse(
          "${baseURL.Urls().baseURL}user/contact-info/user?userId=$userId");
      final response = await http.get(
        contactInfoUri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      final payload = jsonEncode({
        "userId": userId,
        "email":
            emailController.text.isNotEmpty ? emailController.text.trim() : null,
        "phone":
            phoneController.text.isNotEmpty ? phoneController.text.trim() : null,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String contactInfoId = data["id"];
        final updateUri = Uri.parse(
            "${baseURL.Urls().baseURL}user/contact-info/update?userId=$userId&contactInfoId=$contactInfoId");
        await http.put(
          updateUri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: payload,
        ).timeout(const Duration(seconds: 15));
      } else {
        final addUri = Uri.parse(
            "${baseURL.Urls().baseURL}user/contact-info/add?userId=$userId");
        await http.post(
          addUri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: payload,
        ).timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      debugPrint('⚠️ Contact info update failed: $e');
    }
  }

  Future<void> _updateLocationInfo(String userId, String token) async {
    try {
      final locationUri = Uri.parse(
          "${baseURL.Urls().baseURL}userLocation/findByUserId/$userId");
      final response = await http.get(
        locationUri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 15));

      final payload = jsonEncode({
        "userId": userId,
        "locationName": locationTextController.text.trim(),
        "lattitude": latitude,
        "longitude": longitude,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String locationInfoId = data["id"];
        final updateUri = Uri.parse(
            "${baseURL.Urls().baseURL}userLocation/update/$locationInfoId?userId=$userId");
        await http.put(
          updateUri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: payload,
        ).timeout(const Duration(seconds: 15));
      } else {
        final addUri =
            Uri.parse("${baseURL.Urls().baseURL}userLocation/add");
        await http.post(
          addUri,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: payload,
        ).timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      debugPrint('⚠️ Location update failed: $e');
    }
  }

  Future<void> _updateAdvocateInfo(String userId, String token) async {
    try {
      final updateAdvocateUrl = Uri.parse(
          "${baseURL.Urls().baseURL}advocate/update/$advocateId/$userId");
      var advocateRequest = http.MultipartRequest("PUT", updateAdvocateUrl);
      advocateRequest.headers["Authorization"] = "Bearer $token";

      advocateRequest.fields["userId"] = userId;
      advocateRequest.fields["experience"] =
          experienceController.text.trim().isEmpty
              ? "0"
              : experienceController.text.trim();
      advocateRequest.fields["licenseKey"] = licenseKeyController.text.trim();
      advocateRequest.fields["degrees"] = jsonEncode(degrees);
      advocateRequest.fields["workingExperiences"] =
          jsonEncode(workingExperiences);
      advocateRequest.fields["advocateSpeciality"] =
          jsonEncode(selectedSpecialities.toList());

      if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
        advocateRequest.fields["district"] = _selectedDistrict!;
      }

      if (kIsWeb && webCvBytes != null) {
        advocateRequest.files.add(
          http.MultipartFile.fromBytes(
            "file",
            webCvBytes!,
            filename: cvFileName ?? "cv.pdf",
            contentType: http.MediaType("application", "pdf"),
          ),
        );
      } else if (!kIsWeb && cvFile != null) {
        advocateRequest.files.add(
          await http.MultipartFile.fromPath("file", cvFile!.path),
        );
      }

      final streamed = await advocateRequest.send()
          .timeout(const Duration(seconds: 30));
      final advocateResponse = await http.Response.fromStream(streamed);

      if (advocateResponse.statusCode == 200 ||
          advocateResponse.statusCode == 201) {
        print("Advocate updated successfully");
      } else {
        print("Advocate update failed: ${advocateResponse.statusCode}");
      }
    } catch (e) {
      debugPrint('⚠️ Advocate update failed: $e');
    }
  }

  Future<void> _updateGender(String userId, String token) async {
    if (_selectedGender == null) return;
    try {
      final service = UserGenderService();
      if (_existingUserGender != null && _existingUserGender!.id.isNotEmpty) {
        await service
            .updateUserGender(
              id: _existingUserGender!.id,
              userId: userId,
              userGender: _existingUserGender!.copyWith(
                gender: _selectedGender,
              ),
            )
            .timeout(const Duration(seconds: 15));
      } else {
        final created = await service
            .createUserGender(
              userId: userId,
              gender: _selectedGender!,
            )
            .timeout(const Duration(seconds: 15));
        _existingUserGender = created;
      }
    } catch (e) {
      debugPrint('⚠️ Gender update failed: $e');
    }
  }

  Future<void> _updateWorkingExperience(
      String advocateId, String userId, String token) async {
    final model = AdvocateWorkingExperience(
      id: _existingWorkingExperience?.id,
      advocateId: advocateId,
      barAssociation: _barAssociationController.text.trim().isEmpty
          ? null
          : _barAssociationController.text.trim(),
      barControllEnrolment: _barControllEnrolmentController.text.trim().isEmpty
          ? null
          : _barControllEnrolmentController.text.trim(),
      enrollmentDate: _enrollmentDate?.toUtc().toIso8601String(),
      practicingCoat: _practicingCoatController.text.trim().isEmpty
          ? null
          : _practicingCoatController.text.trim(),
      primaryPractice: _primaryPracticeController.text.trim().isEmpty
          ? null
          : _primaryPracticeController.text.trim(),
      yearOfLegalPractice:
          int.tryParse(_legalPracticeYearsController.text.trim()) ?? 0,
      currentChemberName: _chamberController.text.trim(),
      professionalExperience:
          int.tryParse(_professionalExperienceController.text.trim()) ?? 0,
    );

    try {
      if (_existingWorkingExperience?.id != null) {
        await AdvocateWorkingExperienceService.updateExperience(
          model,
          _existingWorkingExperience!.id!,
          userId,
        ).timeout(const Duration(seconds: 15));
      } else {
        await AdvocateWorkingExperienceService.addExperience(model, userId)
            .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      debugPrint('⚠️ Working experience update failed: $e');
    }
  }
Future<void> _updateDocuments(
    String advocateId, String userId, String token) async {
  // ══════════════════════════════════════════════════════════════
  // LOG ENTRY — everything we know at the start
  // ══════════════════════════════════════════════════════════════
  debugPrint('══════════ _updateDocuments START ══════════');
  debugPrint('▶ advocateId          : $advocateId');
  debugPrint('▶ userId              : $userId');
  debugPrint('▶ token (len / head)  : ${token.length} / ${token.length >= 12 ? token.substring(0, 12) : token}...');
  debugPrint('▶ _existingDocuments  : id=${_existingDocuments?.id}, '
      'advocateId=${_existingDocuments?.advocateId}, '
      'attachments=${_existingDocuments?.attachments}');
  debugPrint('▶ _existingDocumentAttachments (${_existingDocumentAttachments.length}) : $_existingDocumentAttachments');
  debugPrint('▶ _documentAttachmentsToDelete (${_documentAttachmentsToDelete.length}) : $_documentAttachmentsToDelete');
  debugPrint('▶ _newDocumentFiles    (${_newDocumentFiles.length}) : '
      '${_newDocumentFiles.map((f) => "${f.name} (${f.size}B)").toList()}');

  final filteredExisting = _existingDocumentAttachments
      .where((id) => !_documentAttachmentsToDelete.contains(id))
      .toList();

  final hasDeletions = _documentAttachmentsToDelete.isNotEmpty;
  final hasAdditions = _newDocumentFiles.isNotEmpty;

  debugPrint('▶ filteredExisting (${filteredExisting.length}) : $filteredExisting');
  debugPrint('▶ hasDeletions=$hasDeletions, hasAdditions=$hasAdditions');

  if (!hasDeletions && !hasAdditions) {
    debugPrint('ℹ️ _updateDocuments: no changes, SKIPPING.');
    debugPrint('══════════ _updateDocuments END (no-op) ══════════');
    return;
  }

  try {
    if (_existingDocuments?.id != null) {
      // ── UPDATE PATH ───────────────────────────────────────────
      final updated = _existingDocuments!.copyWith(
        attachments: filteredExisting,
      );

      final newFilesArg = hasAdditions ? _newDocumentFiles : null;

      debugPrint('── UPDATE branch ──');
      debugPrint('▶ documents.id        : ${updated.id}');
      debugPrint('▶ documents.advocateId: ${updated.advocateId}');
      debugPrint('▶ documents.attachments (${updated.attachments.length}) : ${updated.attachments}');
      debugPrint('▶ documents.toJson()  : ${jsonEncode(updated.toJson())}');
      debugPrint('▶ newFilesArg         : ${newFilesArg == null ? "null" : "${newFilesArg.length} file(s)"}');

      final result = await AdvocateDocumentsService.updateDocuments(
        id: _existingDocuments!.id!,
        userId: userId,
        documents: updated,
        newFiles: newFilesArg,
      ).timeout(const Duration(seconds: 30));

      debugPrint('✅ updateDocuments returned: '
          'id=${result.id}, advocateId=${result.advocateId}, '
          'attachments=${result.attachments}');

      final serverAttachments = List<String>.from(result.attachments);
      final stillHasDeleted = serverAttachments
          .any((a) => _documentAttachmentsToDelete.contains(a));
      final finalAttachments =
          stillHasDeleted ? filteredExisting : serverAttachments;

      debugPrint('▶ serverAttachments   : $serverAttachments');
      debugPrint('▶ stillHasDeleted     : $stillHasDeleted');
      debugPrint('▶ finalAttachments    : $finalAttachments');

      if (mounted) {
        setState(() {
          _existingDocuments = result.copyWith(attachments: finalAttachments);
          _existingDocumentAttachments = finalAttachments;
          _documentAttachmentsToDelete.clear();
          _newDocumentFiles = [];
        });

        if (stillHasDeleted) {
          _showSnackBar(
            "Documents could not be fully updated on the server. Please check your backend.",
            Colors.orange,
          );
        }
      }
    } else {
      // ── CREATE PATH ───────────────────────────────────────────
      debugPrint('── CREATE branch (no existing doc id) ──');

      if (hasAdditions) {
        debugPrint('▶ addDocuments(advocateId=$advocateId, files=${_newDocumentFiles.map((f) => f.name).toList()})');

        final created = await AdvocateDocumentsService.addDocuments(
          advocateId: advocateId,
          files: _newDocumentFiles,
        ).timeout(const Duration(seconds: 30));

        debugPrint('✅ addDocuments returned: '
            'id=${created.id}, advocateId=${created.advocateId}, '
            'attachments=${created.attachments}');

        if (mounted) {
          setState(() {
            _existingDocuments = created;
            _existingDocumentAttachments = List.from(created.attachments);
            _newDocumentFiles = [];
          });
        }
      } else {
        debugPrint('ℹ️ CREATE branch: no additions, nothing to do.');
      }
    }
  } catch (e, st) {
    debugPrint('❌❌❌ _updateDocuments FAILED ❌❌❌');
    debugPrint('▶ exception type      : ${e.runtimeType}');
    debugPrint('▶ exception           : $e');
    debugPrint('▶ stack trace         : $st');
    debugPrint('▶ _existingDocuments  : id=${_existingDocuments?.id}');
    debugPrint('▶ hasDeletions=$hasDeletions, hasAdditions=$hasAdditions');
    debugPrint('▶ filteredExisting    : $filteredExisting');
    debugPrint('▶ newFiles            : ${_newDocumentFiles.map((f) => f.name).toList()}');
    if (mounted) {
      _showSnackBar(
        "Documents could not be updated: $e",
        Colors.orange,
      );
    }
  } finally {
    debugPrint('══════════ _updateDocuments END ══════════');
  }
}

  Future<void> _updateAdditionalInfo(
      String advocateId, String userId, String token) async {
    final model = AdvocateAdditionalInfo(
      id: _existingAdditionalInfo?.id,
      advocateId: advocateId,
      parmanentAdress: _permanentAddressController.text.trim().isEmpty
          ? null
          : _permanentAddressController.text.trim(),
      cityOfUpozila: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      nidNumber:
          _nidController.text.trim().isEmpty ? null : _nidController.text.trim(),
      dateOfBirth: _dateOfBirth?.toUtc().toIso8601String(),
      whatsAppNumber: _whatsAppController.text.trim().isEmpty
          ? null
          : _whatsAppController.text.trim(),
    );

    try {
      if (_existingAdditionalInfo?.id != null) {
        await AdvocateAdditionalInfoService.updateAdditionalInfo(
          model,
          _existingAdditionalInfo!.id!,
          userId,
        ).timeout(const Duration(seconds: 15));
      } else {
        await AdvocateAdditionalInfoService.addAdditionalInfo(model, userId)
            .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      debugPrint('⚠️ Additional info update failed: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _openLoadingDialog() {
    if (_isLoadingDialogOpen) return;
    _isLoadingDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
              SizedBox(height: 16),
              Text("Updating...",
                  style: TextStyle(fontSize: 16, color: Colors.blue)),
              SizedBox(height: 8),
              Text("Please wait",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      _isLoadingDialogOpen = false;
    });
  }

  void _closeLoadingDialog() {
    if (!_isLoadingDialogOpen) return;
    _isLoadingDialogOpen = false;
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildOpenFormButton() {
    return GestureDetector(
      onTap: () => setState(() => showForm = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gavel, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Update Advocate Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
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
              child: Opacity(opacity: value, child: child),
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
                    offset: Offset(0, -5)),
              ],
            ),
            child: Column(
              children: [
                _buildDragHandle(),
                _buildFormHeader(),
                Expanded(child: _buildFormContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 10) setState(() => showForm = false);
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
    );
  }

  Widget _buildFormHeader() {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.gavel, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Advocate Profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('Update your information',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
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
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        children: [
          _buildProfileImage(),
          const SizedBox(height: 24),

          _buildTextField(
            controller: fullNameController,
            label: "Full Name",
            icon: Icons.badge_outlined,
            hint: "Enter your full name",
            focusNode: _fullNameFocus,
            nextFocus: _oldNameFocus,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: oldNameController,
            label: "Username",
            icon: Icons.person_outline,
            readOnly: true,
            focusNode: _oldNameFocus,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: nameController,
            label: "New Username",
            icon: Icons.person,
            hint: "Enter your new username",
            focusNode: _nameFocus,
            nextFocus: _oldPasswordFocus,
          ),
          const SizedBox(height: 16),

          _buildPasswordField(
            controller: oldPasswordController,
            label: "Old Password",
            isVisible: _showOldPassword,
            onToggle: () =>
                setState(() => _showOldPassword = !_showOldPassword),
            focusNode: _oldPasswordFocus,
            nextFocus: _newPasswordFocus,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: passwordController,
            label: "New Password",
            isVisible: _showPassword,
            onToggle: () => setState(() => _showPassword = !_showPassword),
            focusNode: _newPasswordFocus,
            nextFocus: _emailFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: emailController,
            label: "Email",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocus,
            nextFocus: _phoneFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: phoneController,
            label: "Phone Number",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            focusNode: _phoneFocus,
            nextFocus: _experienceFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: locationTextController,
            label: "Location",
            icon: Icons.location_on_outlined,
            readOnly: true,
            onTap: () => _showSnackBar(
                "Tap on the map to select a location", Colors.blue),
          ),
          const SizedBox(height: 16),

          _buildGenderSection(),
          const SizedBox(height: 16),

          _buildDistrictDropdown(),
          const SizedBox(height: 16),

          _buildTextField(
            controller: experienceController,
            label: "Experience (Years)",
            icon: Icons.work_outline,
            hint: "How many years of experience",
            keyboardType: TextInputType.number,
            focusNode: _experienceFocus,
            nextFocus: _licenseFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: licenseKeyController,
            label: "License Key",
            icon: Icons.key,
            hint: "Enter your license key",
            focusNode: _licenseFocus,
          ),
          const SizedBox(height: 20),
          _buildDegreeSection(),
          const SizedBox(height: 20),
          _buildWorkingExperienceSection(),
          const SizedBox(height: 20),
          _buildSpecialistSection(),
          if (cvFileName != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(cvFileName!, overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: downloadCv,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),
          _buildCvSection(),
          const SizedBox(height: 24),

          _buildWorkingExperienceDetailSection(),
          const SizedBox(height: 24),

          _buildDocumentsSection(),
          const SizedBox(height: 24),

          _buildAdditionalInfoSection(),
          const SizedBox(height: 24),

          _buildSubmitButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGenderSection() {
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
              setState(() => _selectedGender = newValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingExperienceDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1),
        const SizedBox(height: 12),
        Row(
          children: const [
            Icon(Icons.work_history, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text(
              "Working Experience Details",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildPlainTextField(
          controller: _barAssociationController,
          label: "Bar Association",
          icon: Icons.account_balance,
        ),
        const SizedBox(height: 12),

        _buildPlainTextField(
          controller: _barControllEnrolmentController,
          label: "Bar Council Enrolment",
          icon: Icons.badge,
        ),
        const SizedBox(height: 12),

        _buildDatePickerField(
          label: "Enrolment Date",
          selectedDate: _enrollmentDate,
          onPick: (d) => setState(() => _enrollmentDate = d),
        ),
        const SizedBox(height: 12),

        _buildPlainTextField(
          controller: _primaryPracticeController,
          label: "Primary Practice",
          icon: Icons.gavel,
        ),
        const SizedBox(height: 12),

        _buildPlainTextField(
          controller: _practicingCoatController,
          label: "Practicing Court",
          icon: Icons.account_balance_rounded,
        ),
        const SizedBox(height: 12),

        _buildPlainTextField(
          controller: _chamberController,
          label: "Current Chamber",
          icon: Icons.business,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildPlainTextField(
                controller: _legalPracticeYearsController,
                label: "Legal Practice Years",
                icon: Icons.timeline,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlainTextField(
                controller: _professionalExperienceController,
                label: "Professional Experience",
                icon: Icons.timeline,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1),
        const SizedBox(height: 12),
        Row(
          children: const [
            Icon(Icons.folder_copy, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text(
              "Documents",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_existingDocumentAttachments.isNotEmpty) ...[
          const Text(
            "Existing Documents:",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._existingDocumentAttachments.map((attId) {
            final willDelete = _documentAttachmentsToDelete.contains(attId);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                willDelete ? Icons.delete_forever : Icons.attach_file,
                color: willDelete ? Colors.red : Colors.blue,
              ),
              title: Text(
                attId,
                style: TextStyle(
                  decoration:
                      willDelete ? TextDecoration.lineThrough : null,
                  color: willDelete ? Colors.red : null,
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  willDelete ? Icons.restore : Icons.delete_outline,
                  color: willDelete ? Colors.green : Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    if (willDelete) {
                      _documentAttachmentsToDelete.remove(attId);
                    } else {
                      _documentAttachmentsToDelete.add(attId);
                    }
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        if (_newDocumentFiles.isNotEmpty) ...[
          const Text(
            "New Documents:",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ..._newDocumentFiles.asMap().entries.map((entry) {
            final idx = entry.key;
            final f = entry.value;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: Text(f.name),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  setState(() => _newDocumentFiles.removeAt(idx));
                },
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text("Add New Documents"),
          onPressed: _pickDocumentFiles,
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1),
        const SizedBox(height: 12),
        Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text(
              "Additional Information",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildPlainTextField(
          controller: _permanentAddressController,
          label: "Permanent Address",
          icon: Icons.home,
        ),
        const SizedBox(height: 12),

        _buildPlainTextField(
          controller: _cityController,
          label: "City / Upazila",
          icon: Icons.location_city,
        ),
        const SizedBox(height: 12),

        _buildPlainTextField(
          controller: _nidController,
          label: "NID Number",
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),

        _buildDatePickerField(
          label: "Date of Birth",
          selectedDate: _dateOfBirth,
          onPick: (d) => setState(() => _dateOfBirth = d),
        ),
        const SizedBox(height: 12),

        _buildPlainTextField(
          controller: _whatsAppController,
          label: "WhatsApp Number",
          icon: Icons.chat,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildPlainTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blue),
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  color: selectedDate == null
                      ? Colors.grey[600]
                      : Colors.black87,
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
            value: (_selectedDistrict != null &&
                    _selectedDistrict!.isNotEmpty &&
                    _districts.contains(_selectedDistrict))
                ? _selectedDistrict
                : null,
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
                selectedDistrict = _selectedDistrict;
              });
            },
          ),
        ),
        if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Chip(
              label: Text(_selectedDistrict!),
              backgroundColor: Colors.blue.withOpacity(0.1),
              labelStyle: const TextStyle(color: Colors.blue),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() => _selectedDistrict = null);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: pickImage,
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [Colors.blue, Colors.blueAccent]),
            boxShadow: [
              BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (pickedImage != null && !kIsWeb)
                  Image.file(pickedImage!, fit: BoxFit.cover)
                else if (webImageBytes != null && kIsWeb)
                  Image.memory(webImageBytes!, fit: BoxFit.cover)
                else
                  Container(
                    color: Colors.white,
                    child: const Icon(Icons.gavel,
                        size: 50, color: Colors.blue),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blueAccent]),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(55),
                        bottomRight: Radius.circular(55),
                      ),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    FocusNode? focusNode,
    FocusNode? nextFocus,
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
        focusNode: focusNode,
        onTap: onTap,
        textInputAction:
            nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onEditingComplete: () {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            FocusScope.of(context).unfocus();
          }
        },
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Future<void> downloadCv() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    final userId = await AuthService.getUserId();

    final response = await http.get(
      Uri.parse("${BASEURL.Urls().baseURL}advocate/cv/$userId"),
      headers: {"Authorization": "Bearer $token"},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No CV available")));
      return;
    }

    final bytes = response.bodyBytes;

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "advocate_cv.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/advocate_cv.pdf');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    FocusNode? focusNode,
    FocusNode? nextFocus,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        focusNode: focusNode,
        textInputAction:
            nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onEditingComplete: () {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            FocusScope.of(context).unfocus();
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blue),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.blue,
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue),
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
                    hintText: "Add a degree",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon:
                        const Icon(Icons.school, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: addDegree,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Add",
                    style: TextStyle(color: Colors.white)),
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
          "Working Experience (Summary)",
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue),
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
                        horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: addWorkingExperience,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Add",
                    style: TextStyle(color: Colors.white)),
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
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: showSpecialityDialog,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        : "${selectedSpecialities.length} specialities selected",
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
                label: Text(d),
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

  Widget _buildCvSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CV (PDF)",
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: pickCv,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                if (cvFileName != null)
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.blue),
                    onPressed: downloadCv,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    iconSize: 20,
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isUpdating
            ? null
            : () async {
                FocusScope.of(context).unfocus();
                _openLoadingDialog();
                try {
                  await _submitForm();
                } catch (e) {
                  debugPrint("Unexpected submit error: $e");
                } finally {
                  _closeLoadingDialog();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 5,
        ),
        child: isUpdating
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Text('Update',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Update Advocate Profile"),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
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
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
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

          if (loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.55),
                child: const Center(
                  child: Card(
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 28, vertical: 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue)),
                          SizedBox(height: 16),
                          Text("Loading your profile...",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.blue)),
                          SizedBox(height: 6),
                          Text("Please wait",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
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
                  mapController.move(_devicePosition!, 15.0);
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          if (!showForm && !loading)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(child: _buildOpenFormButton()),
            ),

          _buildAnimatedForm(),
        ],
      ),
    );
  }
}