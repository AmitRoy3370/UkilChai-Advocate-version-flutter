import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as baseURL;
import 'package:advocatechaiadvocate/Auth/AuthService.dart';
import 'package:http_parser/http_parser.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController oldNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationTextController = TextEditingController();

  bool _showPassword = false, _showOldPassword = false;

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

  bool loading = true;

  final MapController mapController = MapController();

  Stream<Position>? _positionStream;

  get userIdValue => null;

  Future<File?> convertBytesToFile(
      Uint8List bytes, {
        required String extension,
      }) async {
    if (kIsWeb) {
      print('Conversion to File not supported on web. Use bytes directly.');
      return null;
    } else {
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/profile.$extension'; // e.g., 'profile.jpg'
      final file = File(tempPath);
      await file.writeAsBytes(bytes);
      return file;
    }
  }

  Future<void> loadPreviousData() async {
    final token = await AuthService.getToken();

    //print("I am now loading previous data...");

    if (token == null || token.isEmpty) {
      print("No token find at here...");
      return;
    }

    //print("token received in loading previous data :- $token");

    final userId = await AuthService.getUserId();

    final response = await http.get(
      Uri.parse("${baseURL.Urls().baseURL}user/search?userId=$userId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    /*print(
      "search userId :- $userId and response :- ${response.body} and ${response.statusCode}",
    );*/

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        oldNameController.text = data["name"];

        //passwordController.text = data["password"];
      });

      final profileImageId = data["profileImageId"];
      if (profileImageId != null) {
        final profileImageURL =
            "${baseURL.Urls().baseURL}user/download/$profileImageId";
        final profileImageResponse = await http.get(
          Uri.parse(profileImageURL),
          headers: {
            "Accept": "image/*,application/octet-stream",
            "Authorization": "Bearer $token",
          },
        );
        if (profileImageResponse.statusCode == 200 &&
            profileImageResponse.bodyBytes.isNotEmpty) {
          final bytes = profileImageResponse.bodyBytes;
          bool isJpeg =
              bytes.length > 4 &&
                  bytes[0] == 0xFF &&
                  bytes[1] == 0xD8; // JPEG check
          bool isPng =
              bytes.length > 4 &&
                  bytes[0] == 0x89 &&
                  bytes[1] == 0x50 &&
                  bytes[2] == 0x4E &&
                  bytes[3] == 0x47; // PNG check
          bool isLikelyImage = isJpeg || isPng;
          if (isLikelyImage) {
            print("Valid image bytes detected");
            final mimeType = isJpeg ? 'image/jpeg' : 'image/png';
            //final xfile = File.fromUri(Uri.parse(profileImageURL));
            if (mounted) {
              try {
                setState(() async {
                  webImageBytes = bytes;
                  final extension = isJpeg ? 'jpg' : 'png';
                  pickedImage = await convertBytesToFile(
                    bytes,
                    extension: extension,
                  );
                  loading = false;
                });
              } catch (e) {
                print(e.toString());
              }
            }
          } else {
            print("Bytes received but not a valid image format");
            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          }
        }

        final locationURL =
            "${baseURL.Urls().baseURL}userLocation/findByUserId/$userId";

        final locationResponse = await http.get(
          Uri.parse(locationURL),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );

        print(
          "getted location response in update profile :- ${locationResponse.body}",
        );

        if (locationResponse.statusCode == 200) {
          final locationResponseData = jsonDecode(locationResponse.body);

          locationPresent = true;

          setState(() {
            locationTextController.text = locationResponseData["locationName"];
            latitude = locationResponseData["lattitude"];
            longitude = locationResponseData["longitude"];
          });
        } else {
          final locationNameText = locationTextController.text;
          final locationLatitude = latitude;
          final locationLongitude = longitude;

          final uri = Uri.parse(
            "${baseURL.Urls().baseURL}userLocation/create?userId=$userId",
          );

          final response = await http.post(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "userId": userId,
              "locationName": locationNameText,
              "lattitude": locationLatitude,
              "longitude": locationLongitude,
            }),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Location info add successfully")),
            );
            if (kDebugMode) {
              print("Contact info add successfully: ${response.body}");
            }
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text((response.body))));
          }
        }

        final userContactInfoURL =
            "${baseURL.Urls().baseURL}user/contact-info/user?userId=$userId";

        final userContactInfoResponse = await http.get(
          Uri.parse(userContactInfoURL),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );

        if (userContactInfoResponse.statusCode == 200) {
          final userContactInfoResponseData = jsonDecode(
            userContactInfoResponse.body,
          );

          setState(() {
            emailController.text = userContactInfoResponseData["email"];
            phoneController.text = userContactInfoResponseData["phone"];
          });
        } else {
          var uri = Uri.parse(
            "${baseURL.Urls().baseURL}user/contact-info/add?userId=$userId",
          );

          final response = await http.post(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "userId": userId,
              "email": emailController.text.trim(),
              "phone": phoneController.text.trim(),
            }),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Contact info add successfully")),
            );
            if (kDebugMode) {
              print("Contact info add successfully: ${response.body}");
            }
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text((response.body))));
          }
        }
      } else {
        print("Failed to load previous data: ${response.statusCode}");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadPreviousData();
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
      locationPresent ? latitude : position.latitude,
      locationPresent ? longitude : position.longitude,
    );
    String placeName = await getAddressFromLatLng(
      locationPresent ? latitude : position.latitude,
      locationPresent ? longitude : position.longitude,
    );

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
        locationPresent = false;

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
          //setState(() {
          _selectedPosition = pos;
          _selectedPlaceName = name;
          locationTextController.text = /*"Place: $name, Lat: $lat, Lng: $lng"*/
          _selectedPlaceName!;
          _updateMarkers();
          // });
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
      final logInUri = Uri.parse("${baseURL.Urls().baseURL}auth/login");

      final logInResponse = await http.post(
        logInUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userName": oldNameController.text.trim(),
          "password": oldPasswordController.text.trim(),
        }),
      );

      if (logInResponse.statusCode != 200) {
        print("password data is not valid...");

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid credential....")));

        return;
      }

      final decoded = jsonDecode(logInResponse.body);

      String? token = decoded["token"];
      String? userId = decoded["userId"];

      print("Updating userId :- $userId");


      final uri = Uri.parse("${baseURL.Urls().baseURL}user/update/$userId");

      if (kDebugMode) {
        //print("token :- $token and userId :- $userId");
      }

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

      var request = http.MultipartRequest("PUT", uri);
      request.headers['Authorization'] = 'Bearer $token';

      /*request.headers.addAll({
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });*/

      // -------- Text fields ----------
      request.fields["name"] = nameController.text.trim();
      request.fields["password"] = passwordController.text.trim();

      final imageFindingUri = Uri.parse(
        "${baseURL.Urls().baseURL}user/search?userId=$userId",
      );

      final imageFindingResponse = await http.get(
        imageFindingUri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if(imageFindingResponse.statusCode == 200) {
        final imageFindingResponseData = jsonDecode(imageFindingResponse.body);

        if (kDebugMode) {
          print("imageFindingResponseData :- $imageFindingResponseData");
        }

        String? profileImageId = imageFindingResponseData["profileImageId"];

        // optional (send only if backend allows)
        if (profileImageId != null && profileImageId.isNotEmpty) {
          request.fields["profileImageId"] = profileImageId;
        }

        if (kDebugMode) {
          print(
            "profileImageId in update profile section :- ${request
                .fields["profileImageId"]}",
          );
        }
      }

      print("does it has web image byte :- ${webImageBytes != null}");

      // -------- File upload ----------
      if (kIsWeb && webImageBytes != null) {
        if (kIsWeb && webImageBytes != null) {
          if (kDebugMode) {
            print("added file in the request section.......");
          }

          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              webImageBytes!,
              filename: '${nameController.text.trim()}.png',
              contentType: http.MediaType('image', 'png'),
              // 🔥 VERY IMPORTANT
            ),
          );

          print(
            "webImageBytes in update profile section :- ${webImageBytes!.length}",
          );
          print(
            "file :- ${request.files.isNotEmpty}  content type :- ${request.files.elementAt(0).contentType}  filename :- ${request.files.elementAt(0).filename}",
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
        //print("added file :- ${request.files.toString()}");
      }

      if (kDebugMode) {
        print("request body :- ${request.fields}");
      }

      if (kDebugMode) {
        //print("request :- ${request.toString()}");
      }

      print("Sending user update request...");

      // -------- Send request ----------
      final response = await request.send();

      print(
        "updating user response :- ${response.statusCode} ${response.reasonPhrase} ${response.request}",
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);

        print("updating user's response :- $decoded");

        // ✅ JWT token from backend
        //final String token = decoded["token"];
        // final String userId = decoded["userId"];

        final sharedPreferences = await SharedPreferences.getInstance();
        final token = sharedPreferences.getString("jwt_token");
        final userId = sharedPreferences.getString("userId");

        if (kDebugMode) {
          print("token :- $token and userId :- $userId");
        }

        print("received token :- $token");

        // -------- Save token (App + Web) ----------
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", token!);
        await prefs.setString("userId", userId!);

        AuthService.saveToken(token);
        AuthService.saveUserId(userId);

        final sharedPreferences1 = await SharedPreferences.getInstance();
        final _token = sharedPreferences1.getString("jwt_token");

        if (_token == null || token.isEmpty) {
          print("No token found. User not logged in.");
          return;
        }

        String contactInfoFindingURI =
            "${baseURL.Urls().baseURL}user/contact-info/user?userId=$userId";

        final contactInfoFindingUri = Uri.parse(contactInfoFindingURI);

        final responseForContactInfoFinding = await http.get(
          contactInfoFindingUri,
          headers: {
            "Authorization": "Bearer $_token", // Key: Use 'Bearer ' prefix
            "Content-Type":
            "application/json", // If JSON body; adjust as needed
          },
        );

        if (responseForContactInfoFinding.statusCode != 200) {
          final contactInfoUri = Uri.parse(
            "${baseURL.Urls().baseURL}user/contact-info/add?userId=$userId",
          );

          final responseForContactInfo = await http.post(
            contactInfoUri,
            headers: {
              "Authorization": "Bearer $_token", // Key: Use 'Bearer ' prefix
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Contact info add successfully")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Contact info not added.....")),
            );
          }
        } else {
          var contactInfoResponseBody = jsonDecode(
            responseForContactInfoFinding.body,
          );

          String contactInfoID = contactInfoResponseBody["id"];

          String contactInfoUri =
              "${baseURL.Urls().baseURL}user/contact-info/update?userId=$userId&contactInfoId=$contactInfoID";

          final url = Uri.parse(contactInfoUri);

          final responseForContactInfo = await http.put(
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseForContactInfo.body)),
            );
          }
        }

        String locationFindURL =
            "${baseURL.Urls().baseURL}userLocation/findByUserId/$userId";

        final locationFindUri = Uri.parse(locationFindURL);

        final responseForLocationFinding = await http.get(
          locationFindUri,
          headers: {
            "Authorization": "Bearer $_token", // Key: Use 'Bearer ' prefix
            "Content-Type":
            "application/json", // If JSON body; adjust as needed
          },
        );

        if (responseForLocationFinding.statusCode != 200) {
          final String locationUrl =
              "${baseURL.Urls().baseURL}userLocation/add";

          final loaction = Uri.parse(locationUrl);

          final sharedPreferences1 = await SharedPreferences.getInstance();
          final token1 = sharedPreferences1.getString("jwt_token");

          if (token1 == null || token.isEmpty) {
            //print("No token found. User not logged in.");
            return;
          }

          //print("latitude :- $lattitude longitude :- $longititude");

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
              "lattitude": latitude,
              "longitude": longitude,
            }),
          );

          if (responseForContactInfo1.statusCode == 200 ||
              responseForContactInfo1.statusCode == 201) {
            //print("Contact info added successfully");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Location info add successfully")),
            );
            if (kDebugMode) {
              //print(
              // "Contact info add successfully: ${responseForContactInfo1.body}",
              // );
            }
          } else {
            // print("location info add failed ${responseForContactInfo1.body}");
            if (kDebugMode) {
              //print("Location info add failed: ${responseForContactInfo1.body}");
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to add location...")),
            );
          }
        } else {
          print("location update :- ${responseForLocationFinding.body}");

          var contactInfoResponseBody1 = jsonDecode(
            responseForLocationFinding.body,
          );

          if (kDebugMode) {
            print("contactInfoResponseBody1 :- $contactInfoResponseBody1");
          }

          final locationDecoded = jsonDecode(responseForLocationFinding.body);

          if (kDebugMode) {
            print("locationDecoded :- $locationDecoded");
          }

          String locationInfoId = locationDecoded["id"];

          final String locationUrl =
              "${baseURL.Urls().baseURL}userLocation/update/$locationInfoId?userId=$userId";

          final loaction = Uri.parse(locationUrl);

          final sharedPreferences11 = await SharedPreferences.getInstance();
          final token1 = sharedPreferences11.getString("jwt_token");

          if (token1 == null || token.isEmpty) {
            print("No token found. User not logged in.");
            return;
          }

          print("latitude :- $latitude longitude :- $longitude");

          final responseForContactInfo1 = await http.put(
            loaction,
            headers: {
              "Authorization": "Bearer $token1", // Key: Use 'Bearer ' prefix
              "Content-Type":
              "application/json", // If JSON body; adjust as needed
            },
            body: jsonEncode({
              "userId": userId,
              "locationName": locationTextController.text.trim(),
              "lattitude": latitude,
              "longitude": longitude,
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
              print(
                "Location info add failed: ${responseForContactInfo1.body}",
              );
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to add location...")),
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful")),
        );

        if (kDebugMode) {
          // print("JWT TOKEN => $token");
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
                              readOnly: true,
                              controller: oldNameController,
                              decoration: const InputDecoration(
                                labelText: "Old Name",
                              ),
                            ),
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: "New Name",
                              ),
                            ),
                            TextField(
                              controller: oldPasswordController,
                              obscureText: !_showOldPassword,
                              decoration: InputDecoration(
                                labelText: "Old Password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showOldPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showOldPassword = !_showOldPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            TextField(
                              controller: passwordController,
                              obscureText: !_showPassword,
                              decoration: InputDecoration(
                                labelText: "New Password",
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
