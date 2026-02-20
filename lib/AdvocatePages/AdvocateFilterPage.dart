import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/AuthService.dart';

import '../Utils/BaseURL.dart' as BASE_URL;
import '../Utils/AdvocateSpeciality.dart';
import '../AdvocatePages/AdvocateDetailsModel.dart';
import 'AdvocateDetails.dart';

class AdvocateFilterPage extends StatefulWidget {
  const AdvocateFilterPage({super.key});

  @override
  State<AdvocateFilterPage> createState() => _AdvocateFilterPageState();
}

class _AdvocateFilterPageState extends State<AdvocateFilterPage> {
  AdvocateSpeciality? selectedSpeciality;
  bool loading = true;

  List<AdvocateDetailsModel> list = [];

  @override
  void initState() {
    super.initState();
    getAdvocateList(); // 🔥 initially load all
  }

  // Get the advocate name
  Future<String> getAdvocateName(String? advocateId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final url = "${BASE_URL.Urls().baseURL}advocate/$advocateId";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final userId = body["userId"];

      return getNameFromUser(userId);
    } else {
      return "";
    }
  }

  // ---------------- GET USER NAME ----------------
  Future<String> getNameFromUser(String? userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final url = "${BASE_URL.Urls().baseURL}user/search?userId=$userId";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body["name"] ?? "";
    }
    return "";
  }

  // ---------------- FETCH ALL ----------------
  Future<void> getAdvocateList() async {
    setState(() {
      loading = true;
      list.clear();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.get(
        Uri.parse("${BASE_URL.Urls().baseURL}advocate/all"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to load advocates");
      }

      final List responseData = jsonDecode(response.body);

      for (final item in responseData) {
        final advocateDecoded = item as Map<String, dynamic>;
        final String userId = advocateDecoded["userId"];

        // ---------- USER ----------
        final userRes = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user/search?userId=$userId"),
          headers: {"Authorization": "Bearer $token"},
        );

        print("user response for ${getNameFromUser(userId)} is ${userRes.statusCode}");

        if (userRes.statusCode != 200) continue;
        final user = jsonDecode(userRes.body);

        // ---------- CONTACT ----------
        String? email;
        String? phone;

        final contactRes = await http.get(
          Uri.parse(
            "${BASE_URL.Urls().baseURL}user/contact-info/user?userId=$userId",
          ),
          headers: {"Authorization": "Bearer $token"},
        );

        print("Contact response for ${getNameFromUser(userId)} is ${contactRes.statusCode}");


        if (contactRes.statusCode == 200) {
          final contact = jsonDecode(contactRes.body);
          email = contact["email"];
          phone = contact["phone"];
        }

        // ---------- LOCATION ----------
        String? locationName;
        double? lat;
        double? lng;

        final locationRes = await http.get(
          Uri.parse(
            "${BASE_URL.Urls().baseURL}userLocation/findByUserId/$userId",
          ),
          headers: {"Authorization": "Bearer $token"},
        );

        print("location response for ${getNameFromUser(userId)} is ${locationRes.statusCode}");


        if (locationRes.statusCode == 200) {
          final location = jsonDecode(locationRes.body);
          locationName = location["locationName"];
          lat = location["lattitude"];
          lng = location["longitude"];
        }

        // ---------- BUILD MODEL ----------
        final model = AdvocateDetailsModel.defaultConstructor()
          ..id = advocateDecoded["id"]
          ..userId = userId
          ..name = user["name"]
          ..profileImageId = user["profileImageId"]
          ..experience = advocateDecoded["experience"]
          ..licenseKey = advocateDecoded["licenseKey"]
          ..advocateSpeciality = advocateDecoded["advocateSpeciality"] ?? []
          ..degrees = advocateDecoded["degrees"] ?? []
          ..workingExperiences = advocateDecoded["workingExperiences"] ?? []
          ..email = email
          ..phone = phone
          ..locationName = locationName
          ..lattitude = lat
          ..longitude = lng;

        list.add(model);
      }
    } catch (e) {
      debugPrint("Error loading advocates: $e");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // ---------------- FETCH BY SPECIALITY ----------------
  Future<void> fetchBySpeciality(AdvocateSpeciality speciality) async {
    setState(() => loading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate/search/speciality/${speciality.name}",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "content-type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List responseData = jsonDecode(response.body);

      List<AdvocateDetailsModel> models = [];

      for (final item in responseData) {
        final advocateDecoded = item as Map<String, dynamic>;
        final String userId = advocateDecoded["userId"];

        // ---------- USER ----------
        final userRes = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user/search?userId=$userId"),
          headers: {"Authorization": "Bearer $token"},
        );

        print("user response for ${getNameFromUser(userId)} is ${userRes.statusCode}");

        if (userRes.statusCode != 200) continue;
        final user = jsonDecode(userRes.body);

        // ---------- CONTACT ----------
        String? email;
        String? phone;

        final contactRes = await http.get(
          Uri.parse(
            "${BASE_URL.Urls().baseURL}user/contact-info/user?userId=$userId",
          ),
          headers: {"Authorization": "Bearer $token"},
        );

        print("Contact response for ${getNameFromUser(userId)} is ${contactRes.statusCode}");


        if (contactRes.statusCode == 200) {
          final contact = jsonDecode(contactRes.body);
          email = contact["email"];
          phone = contact["phone"];
        }

        // ---------- LOCATION ----------
        String? locationName;
        double? lat;
        double? lng;

        final locationRes = await http.get(
          Uri.parse(
            "${BASE_URL.Urls().baseURL}userLocation/findByUserId/$userId",
          ),
          headers: {"Authorization": "Bearer $token"},
        );

        print("location response for ${getNameFromUser(userId)} is ${locationRes.statusCode}");


        if (locationRes.statusCode == 200) {
          final location = jsonDecode(locationRes.body);
          locationName = location["locationName"];
          lat = location["lattitude"];
          lng = location["longitude"];
        }

        // ---------- BUILD MODEL ----------
        final model = AdvocateDetailsModel.defaultConstructor()
          ..id = advocateDecoded["id"]
          ..userId = userId
          ..name = user["name"]
          ..profileImageId = user["profileImageId"]
          ..experience = advocateDecoded["experience"]
          ..licenseKey = advocateDecoded["licenseKey"]
          ..advocateSpeciality = advocateDecoded["advocateSpeciality"] ?? []
          ..degrees = advocateDecoded["degrees"] ?? []
          ..workingExperiences = advocateDecoded["workingExperiences"] ?? []
          ..email = email
          ..phone = phone
          ..locationName = locationName
          ..lattitude = lat
          ..longitude = lng;

        models.add(model);
      }
      setState(() {
        list = /*body.map((e) => AdvocateDetailsModel.fromJson(e)).toList()*/ models;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        list.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find Advocate")),
      body: Column(
        children: [
          // ---------------- DROPDOWN ----------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<AdvocateSpeciality>(
              value: selectedSpeciality,
              decoration: const InputDecoration(
                labelText: "Filter by Speciality",
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text("All Specialities"),
                ),
                ...AdvocateSpeciality.values.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.label), // 👈 from enum extension
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => selectedSpeciality = value);

                if (value == null) {
                  getAdvocateList();
                } else {
                  fetchBySpeciality(value);
                }
              },
            ),
          ),

          // ---------------- LIST ----------------
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? const Center(child: Text("No advocates found"))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final adv = list[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AdvocateDetails(advocateDetailsModel: adv),
                              ),
                            );
                          },
                          leading: const Icon(Icons.person),
                          title: Text("Advocate: ${adv.name ?? "Unknown"}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Experience: ${adv.experience ?? 0} years"),
                              Text(
                                "Speciality: ${adv.advocateSpeciality.join(", ")}",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
