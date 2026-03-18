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

    final response = await http.get(
      uri,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load advocates");
    }

    final List responseData = jsonDecode(response.body);
    List<AdvocateDetailsModel> list = [];

    for (var item in responseData) {
      Map<String, dynamic> advocateDecoded = item;

      String userId = advocateDecoded["userId"];

      print("getting userId :- $userId");

      final userResponse = await http.get(
        Uri.parse("${baseURL.Urls().baseURL}user/search?userId=$userId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (userResponse.statusCode == 200) {
        final user = jsonDecode(userResponse.body);

        final contactResponse = await http.get(
          Uri.parse(
            "${baseURL.Urls().baseURL}user/contact-info/user?userId=$userId",
          ),
          headers: {"Authorization": "Bearer $token"},
        );

        var advocateDetailsModel = AdvocateDetailsModel.defaultConstructor();

        advocateDetailsModel.name = user["name"];
        advocateDetailsModel.profileImageId = user["profileImageId"];
        advocateDetailsModel.userId = userId;

        advocateDetailsModel.id = advocateDecoded["id"];
        advocateDetailsModel.experience = advocateDecoded["experience"];
        advocateDetailsModel.licenseKey = advocateDecoded["licenseKey"];
        advocateDetailsModel.advocateSpeciality =
            advocateDecoded["advocateSpeciality"];
        advocateDetailsModel.degrees = advocateDecoded["degrees"];
        advocateDetailsModel.workingExperiences =
            advocateDecoded["workingExperiences"];
        advocateDetailsModel.password = user["password"];

        if (contactResponse.statusCode == 200) {
          final contact = jsonDecode(contactResponse.body);

          final locationResponse = await http.get(
            Uri.parse(
              "${baseURL.Urls().baseURL}userLocation/findByUserId/$userId",
            ),
            headers: {"Authorization": "Bearer $token"},
          );

          advocateDetailsModel.email = contact["email"];
          advocateDetailsModel.phone = contact["phone"];

          if (locationResponse.statusCode == 200) {
            final location = jsonDecode(locationResponse.body);

            advocateDetailsModel.locationName = location["locationName"];
            advocateDetailsModel.lattitude = location["lattitude"];
            advocateDetailsModel.longitude = location["longitude"];

            /*list.add(
              AdvocateDetailsModel(
                advocateDecoded["id"],
                user["name"],
                contact["email"],
                contact["phone"],
                user["profileImageId"],
                location["locationName"],
                location["lattitude"],
                location["longitude"],
                user["password"],
                advocateDecoded["experience"],
                advocateDecoded["licenseKey"],
                advocateDecoded["advocateSpeciality"],
                advocateDecoded["degrees"],
                advocateDecoded["workingExperiences"],
                userId
              ),
            );*/
          }
        }

        if (advocateDetailsModel.name != null &&
            advocateDetailsModel.userId != null &&
            advocateDetailsModel.id != null) {
          list.add(advocateDetailsModel);
        }
      }
    }

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
                                (advocate.advocateSpeciality).cast<String>(),
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
