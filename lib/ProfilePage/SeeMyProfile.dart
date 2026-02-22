import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:advocatechaiadvocate/Auth/AuthService.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASEURL;

import 'Profile.dart';
import 'ProfileImageWidget.dart';
import 'UpdateProfile.dart';

class SeeMyProfile extends StatefulWidget {
  const SeeMyProfile({super.key});

  @override
  State<StatefulWidget> createState() {
    return SeeProfileState();
  }
}

class SeeProfileState extends State<SeeMyProfile> {
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

  Profile profile = Profile.defaultConstructor();

  Future<void> collectProfileInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString("jwt_token");
    String? userId = prefs.getString("userId");

    if (token == null || token.isEmpty) {
      return;
    }

    if (userId == null || userId.isEmpty) {
      return;
    }

    //AuthService.saveToken(token);
    //AuthService.saveUserId(userId);

    if (kDebugMode) {
      print("token :- $token and userId :- $userId");
    }

    var url = Uri.parse("${BASEURL.Urls().baseURL}user/search?userId=$userId");

    var response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      setState(() {
        profile.id = data["id"];
        profile.name = data["name"];
        profile.password = data["password"];
        profile.profileImageId = data["profileImageId"];
      });

      var contactInfoURL = Uri.parse(
        "${BASEURL.Urls().baseURL}user/contact-info/user?userId=$userId",
      );

      var contactInfoResponse = await http.get(
        contactInfoURL,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (contactInfoResponse.statusCode == 200) {
        var contactInfoData = jsonDecode(contactInfoResponse.body);

        setState(() {
          profile.email = contactInfoData["email"];
          profile.phone = contactInfoData["phone"];
        });
      } else {
        print(
          "Failed to load previous data: ${response.statusCode} and ${response.body}",
        );
      }

      var locationURI = Uri.parse(
        "${BASEURL.Urls().baseURL}userLocation/findByUserId/$userId",
      );

      final locationResponse = await http.get(
        locationURI,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (locationResponse.statusCode == 200) {
        var locationResponseData = jsonDecode(locationResponse.body);

        setState(() {
          profile.lattitude = locationResponseData["lattitude"];
          profile.longitude = locationResponseData["longitude"];
          profile.locationName = locationResponseData["locationName"];
        });
      }

      if (kDebugMode) {
        print("finding profile info :- ${profile.toString()}");
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    collectProfileInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// -------- PROFILE IMAGE ----------
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrangeAccent],
                ),
              ),
              child: const ProfileImageWidget(radius: 55),
            ),

            const SizedBox(height: 16),

            /// -------- NAME ----------
            Text(
              profile.name ?? "Your Name",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "User Profile",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),

            const SizedBox(height: 30),

            /// -------- PROFILE INFO CARD ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _profileRow(Icons.email, "Email", profile.email),
                  _divider(),
                  _profileRow(Icons.phone, "Phone", profile.phone),
                  _divider(),
                  _profileRow(
                    Icons.location_on,
                    "Location",
                    profile.locationName,
                  ),
                  _divider(),
                  _profileRow(
                    Icons.map,
                    "Latitude",
                    profile.lattitude?.toStringAsFixed(5),
                  ),
                  _divider(),
                  _profileRow(
                    Icons.map_outlined,
                    "Longitude",
                    profile.longitude?.toStringAsFixed(5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// -------- ACTION BUTTON ----------
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UpdateProfile(),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: 22),
        const SizedBox(width: 12),
        Text(
          "$label:",
          style: TextStyle(color: Colors.black, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value ?? "Not available",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Colors.black, thickness: 1),
    );
  }
}
