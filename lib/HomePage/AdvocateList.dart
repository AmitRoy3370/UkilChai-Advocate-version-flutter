import 'dart:convert';
import 'package:advocatechaiadvocate/AdvocatePages/AdvocateDetailsModel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as baseURL;
import 'package:advocatechaiadvocate/Auth/AuthService.dart';

import '../AdvocatePages/AdvocateDetails.dart';

class AdvocateList extends StatelessWidget {
  const AdvocateList({super.key});

  Future<Uint8List?> fetchProfileImage(String? imageId) async {
    if (imageId == null || imageId.isEmpty) return null;

    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("${baseURL.Urls().baseURL}user/download/$imageId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return null;
  }

  Future<List<AdvocateDetailsModel>> getAdvocateList() async {
    final token = await AuthService.getToken();
    final uri = Uri.parse("${baseURL.Urls().baseURL}advocate/all");

    print("fetching all advocates from $uri");

    final response = await http.get(
      uri,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load advocates");
    }

    print("advocate status code :- ${response.statusCode}");

    final List responseData = jsonDecode(response.body);

    print("advocate response :- $responseData");

    List<AdvocateDetailsModel> list = [];

    for (var item in responseData) {
      final advocateDecoded = item as Map<String, dynamic>;

      print("advocate decoded :- $advocateDecoded");

      final String userId = advocateDecoded["userId"];

      // ---------- USER ----------
      /*final userRes = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user/search?userId=$userId"),
          headers: {"Authorization": "Bearer $token"},
        );

        print("user response for ${getNameFromUser(userId)} is ${userRes.statusCode}");

        if (userRes.statusCode != 200) continue;
        final user = jsonDecode(userRes.body);*/

      // ---------- CONTACT ----------
      String? email;
      String? phone;

      /*final contactRes = await http.get(
          Uri.parse(
            "${BASE_URL.Urls().baseURL}user/contact-info/user?userId=$userId",
          ),
          headers: {"Authorization": "Bearer $token"},
        );

        print("Contact response for ${getNameFromUser(userId)} is ${contactRes.statusCode}");*/

      //if (contactRes.statusCode == 200) {
      //final contact = jsonDecode(contactRes.body);
      email = advocateDecoded["email"];
      phone = advocateDecoded["phone"];
      //}

      // ---------- LOCATION ----------
      String? locationName;
      double? lat;
      double? lng;

      /*final locationRes = await http.get(
          Uri.parse(
            "${BASE_URL.Urls().baseURL}userLocation/findByUserId/$userId",
          ),
          headers: {"Authorization": "Bearer $token"},
        );

        print("location response for ${getNameFromUser(userId)} is ${locationRes.statusCode}");
        */

      //if (locationRes.statusCode == 200) {
      //final location = jsonDecode(locationRes.body);
      locationName = advocateDecoded["locationName"];
      lat = advocateDecoded["lattitude"];
      lng = advocateDecoded["longitude"];
      //}

      // ---------- BUILD MODEL ----------
      /*final model = AdvocateDetailsModel.defaultConstructor()
        ..id = advocateDecoded["id"]
        ..userId = userId
        ..name = advocateDecoded["name"]
        ..profileImageId = advocateDecoded["profileImageId"]
        ..experience = advocateDecoded["experience"]
        ..licenseKey = advocateDecoded["licenseKey"]
        ..advocateSpeciality = advocateDecoded["advocateSpeciality"] ?? []
        ..degrees = advocateDecoded["degrees"] ?? []
        ..workingExperiences = advocateDecoded["workingExperiences"] ?? []
        ..email = email
        ..phone = phone
        ..locationName = locationName
        ..lattitude = lat
        ..longitude = lng
        ..contactInfoId = advocateDecoded['advocateDecoded']
        ..locationId = advocateDecoded['locationId']
        ..cvHexKey = advocateDecoded['cvHexKey'];*/

      final model = AdvocateDetailsModel.defaultConstructor()
        ..id = advocateDecoded["id"]?.toString()
        ..userId = userId
        ..name = advocateDecoded["name"]?.toString()
        ..profileImageId = advocateDecoded["profileImageId"]?.toString()
        ..experience = (advocateDecoded["experience"] ?? 0)
        ..licenseKey = advocateDecoded["licenseKey"]?.toString()

      // 🔥 FIXED LIST CONVERSION
        ..advocateSpeciality = advocateDecoded["advocateSpeciality"] != null
            ? List<String>.from(
            advocateDecoded["advocateSpeciality"].map((e) => e.toString()))
            : []

        ..degrees = advocateDecoded["degrees"] != null
            ? List<String>.from(
            advocateDecoded["degrees"].map((e) => e.toString()))
            : []

        ..workingExperiences = advocateDecoded["workingExperiences"] != null
            ? List<String>.from(
            advocateDecoded["workingExperiences"].map((e) => e.toString()))
            : []

        ..email = email
        ..phone = phone
        ..locationName = locationName
        ..lattitude = lat != null ? double.tryParse(lat.toString()) : null
        ..longitude = lng != null ? double.tryParse(lng.toString()) : null

      // ❗ ALSO FIX THIS (WRONG KEY)
        ..contactInfoId = advocateDecoded['contactInfoId']?.toString()
        ..locationId = advocateDecoded['locationId']?.toString()
        ..cvHexKey = advocateDecoded['cvHexKey']?.toString();

      print("advocate model :- $model");

      list.add(model);
    }

    print("all advocates :- $list");

    return list;
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _listSection(String title, List<String> items) {
    return _section(
      title,
      items.isEmpty
          ? [
        const Text(
          "No data available",
          style: TextStyle(color: Colors.black),
        ),
      ]
          : items.map((e) => _row(Icons.check_circle, e)).toList(),
    );
  }

  Widget _row(IconData icon, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value ?? "Not available",
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: getAdvocateList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: Colors.black),
            ),
          );
        }

        final advocates = snapshot.data!;

        if (kDebugMode) {
          print("advocates :- $advocates");
        }

        if (advocates.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "No advocates found",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Top advocates list...",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: advocates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cards per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final AdvocateDetailsModel advocate = advocates[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdvocateDetails(advocateDetailsModel: advocate),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              FutureBuilder<Uint8List?>(
                                future: fetchProfileImage(
                                  advocate.profileImageId,
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const CircleAvatar(
                                      radius: 55,
                                      child: Icon(Icons.person, size: 55),
                                    );
                                  }

                                  return CircleAvatar(
                                    radius: 55,
                                    backgroundImage: MemoryImage(
                                      snapshot.data!,
                                    ),
                                  );
                                },
                              ),

                              Text(
                                advocate.name ?? "Unknown",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                "${advocate.experience ?? 0} years experience",
                                style: TextStyle(color: Colors.black),
                              ),
                              _section("Professional Info", [
                                _row(
                                  Icons.badge,
                                  "License: ${advocate.licenseKey}",
                                ),
                              ]),

                              _listSection(
                                "Specialities",
                                (advocate.advocateSpeciality ?? [])
                                    .map((e) => e.toString())
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
