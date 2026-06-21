import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import '../Utils/AdvocateSpeciality.dart';
import '../AdvocatePages/AdvocateDetailsModel.dart';
import 'AdvocateDetails.dart';
import '../PageTransition.dart';
import '../main.dart'; // Add this import for MyHomePage

class AdvocateFilterPage extends StatefulWidget {
  const AdvocateFilterPage({super.key});

  @override
  State<AdvocateFilterPage> createState() => _AdvocateFilterPageState();
}

class _AdvocateFilterPageState extends State<AdvocateFilterPage> {
  AdvocateSpeciality? selectedSpeciality;
  bool loading = true;
  List<AdvocateDetailsModel> list = [];
  String? selectedLocation;
  List<String> allLocations = [
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
  'Cox\'s Bazar',
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

  // Smooth animations only - no flip/mirror effects
  final List<PageTransitionType> _smoothAnimations = AnimatedRoute.getCompanySafeAnimations();

  PageTransitionType _getRandomAnimation() {
    final random = Random().nextInt(_smoothAnimations.length);
    return _smoothAnimations[random];
  }

  @override
  void initState() {
    super.initState();
    getAdvocateList();
  }

  // Method to navigate back to main page
  void _navigateToMainPage() {
    // This will clear all previous routes and go to home page (index 0)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'উকিল চাই')),
      (route) => false,
    );
  }

  Future<Uint8List?> fetchProfileImage(String? imageId) async {
    if (imageId == null || imageId.isEmpty) return null;

    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}user/download/$imageId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return null;
  }

  Future<String> getAdvocateName(String? advocateId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final url = "${BASE_URL.Urls().baseURL}advocate/$advocateId";
    final response = await http.get(
      Uri.parse(url),
      headers: {"content-type": "application/json", "Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final userId = body["userId"];
      return getNameFromUser(userId);
    }
    return "";
  }

  Future<String> getNameFromUser(String? userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final url = "${BASE_URL.Urls().baseURL}user/search?userId=$userId";
    final response = await http.get(
      Uri.parse(url),
      headers: {"content-type": "application/json", "Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body["name"] ?? "";
    }
    return "";
  }

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

        String? email = advocateDecoded["email"];
        String? phone = advocateDecoded["phone"];
        String? locationName = advocateDecoded["locationName"];
        double? lat = advocateDecoded["lattitude"];
        double? lng = advocateDecoded["longitude"];
        String? district = advocateDecoded['district'];

        final model = AdvocateDetailsModel.defaultConstructor()
          ..id = advocateDecoded["id"]?.toString()
          ..userId = userId
          ..name = advocateDecoded["name"]?.toString()
          ..profileImageId = advocateDecoded["profileImageId"]?.toString()
          ..experience = (advocateDecoded["experience"] ?? 0)
          ..licenseKey = advocateDecoded["licenseKey"]?.toString()
          ..advocateSpeciality = advocateDecoded["advocateSpeciality"] != null
              ? List<String>.from(advocateDecoded["advocateSpeciality"].map((e) => e.toString()))
              : []
          ..degrees = advocateDecoded["degrees"] != null
              ? List<String>.from(advocateDecoded["degrees"].map((e) => e.toString()))
              : []
          ..workingExperiences = advocateDecoded["workingExperiences"] != null
              ? List<String>.from(advocateDecoded["workingExperiences"].map((e) => e.toString()))
              : []
          ..email = email
          ..phone = phone
          ..locationName = locationName
          ..lattitude = lat != null ? double.tryParse(lat.toString()) : null
          ..longitude = lng != null ? double.tryParse(lng.toString()) : null
          ..contactInfoId = advocateDecoded['contactInfoId']?.toString()
          ..locationId = advocateDecoded['locationId']?.toString()
          ..cvHexKey = advocateDecoded['cvHexKey']?.toString()
          ..district = advocateDecoded['district'];

        list.add(model);

        /*if (locationName != null && locationName.isNotEmpty) {
          if (!allLocations.contains(locationName)) {
            allLocations.add(locationName);
          }
        }*/
      }
    } catch (e) {
      debugPrint("Error loading advocates: $e");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> fetchBySpeciality(AdvocateSpeciality speciality) async {
    setState(() => loading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}advocate/search/speciality/${speciality.name}"),
      headers: {"Authorization": "Bearer $token", "content-type": "application/json"},
    );

    if (response.statusCode == 200) {
      final List responseData = jsonDecode(response.body);
      List<AdvocateDetailsModel> models = [];

      for (final item in responseData) {
        final advocateDecoded = item as Map<String, dynamic>;
        final String userId = advocateDecoded["userId"];

        String? email = advocateDecoded["email"];
        String? phone = advocateDecoded["phone"];
        String? locationName = advocateDecoded["locationName"];
        double? lat = advocateDecoded["lattitude"];
        double? lng = advocateDecoded["longitude"];

        final model = AdvocateDetailsModel.defaultConstructor()
          ..id = advocateDecoded["id"]?.toString()
          ..userId = userId
          ..name = advocateDecoded["name"]?.toString()
          ..profileImageId = advocateDecoded["profileImageId"]?.toString()
          ..experience = (advocateDecoded["experience"] ?? 0)
          ..licenseKey = advocateDecoded["licenseKey"]?.toString()
          ..advocateSpeciality = advocateDecoded["advocateSpeciality"] != null
              ? List<String>.from(advocateDecoded["advocateSpeciality"].map((e) => e.toString()))
              : []
          ..degrees = advocateDecoded["degrees"] != null
              ? List<String>.from(advocateDecoded["degrees"].map((e) => e.toString()))
              : []
          ..workingExperiences = advocateDecoded["workingExperiences"] != null
              ? List<String>.from(advocateDecoded["workingExperiences"].map((e) => e.toString()))
              : []
          ..email = email
          ..phone = phone
          ..locationName = locationName
          ..lattitude = lat != null ? double.tryParse(lat.toString()) : null
          ..longitude = lng != null ? double.tryParse(lng.toString()) : null
          ..contactInfoId = advocateDecoded['contactInfoId']?.toString()
          ..locationId = advocateDecoded['locationId']?.toString()
          ..cvHexKey = advocateDecoded['cvHexKey']?.toString()
          ..district = advocateDecoded['district'];

        models.add(model);
      }
      setState(() {
        list = models;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        list.clear();
      });
    }
  }

  Future<void> fetchByLocation(String location) async {
    setState(() {
      loading = true;
      list.clear();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.get(
        Uri.parse("${BASE_URL.Urls().baseURL}advocate/find/district/$location"),
        headers: {"Authorization": "Bearer $token", "content-type": "application/json"},
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to filter by location");
      }

      final List responseData = jsonDecode(response.body);
      List<AdvocateDetailsModel> models = [];

      for (final item in responseData) {
        final advocateDecoded = item as Map<String, dynamic>;
        final String userId = advocateDecoded["userId"];

        String? email = advocateDecoded["email"];
        String? phone = advocateDecoded["phone"];
        String? locationName = advocateDecoded["locationName"];
        double? lat = advocateDecoded["lattitude"];
        double? lng = advocateDecoded["longitude"];

        final model = AdvocateDetailsModel.defaultConstructor()
          ..id = advocateDecoded["id"]?.toString()
          ..userId = userId
          ..name = advocateDecoded["name"]?.toString()
          ..profileImageId = advocateDecoded["profileImageId"]?.toString()
          ..experience = (advocateDecoded["experience"] ?? 0)
          ..licenseKey = advocateDecoded["licenseKey"]?.toString()
          ..advocateSpeciality = advocateDecoded["advocateSpeciality"] != null
              ? List<String>.from(advocateDecoded["advocateSpeciality"].map((e) => e.toString()))
              : []
          ..degrees = advocateDecoded["degrees"] != null
              ? List<String>.from(advocateDecoded["degrees"].map((e) => e.toString()))
              : []
          ..workingExperiences = advocateDecoded["workingExperiences"] != null
              ? List<String>.from(advocateDecoded["workingExperiences"].map((e) => e.toString()))
              : []
          ..email = email
          ..phone = phone
          ..locationName = locationName
          ..lattitude = lat != null ? double.tryParse(lat.toString()) : null
          ..longitude = lng != null ? double.tryParse(lng.toString()) : null
          ..contactInfoId = advocateDecoded['contactInfoId']?.toString()
          ..locationId = advocateDecoded['locationId']?.toString()
          ..cvHexKey = advocateDecoded['cvHexKey']?.toString()
          ..district = advocateDecoded['district'];

        models.add(model);
      }

      setState(() {
        list = models;
        loading = false;
      });
    } catch (e) {
      debugPrint("Location filter error: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // When back button is pressed, navigate to main page
        _navigateToMainPage();
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            "Find Advocate",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
            onPressed: _navigateToMainPage, // Use the same method for back button
          ),
        ),
        body: Column(
          children: [
            // Stats Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A237E), // Deep Navy - Trust & Authority
                    const Color(0xFF283593), // Indigo - Professionalism
                    const Color(0xFF3949AB), // Lighter Indigo - Approachability
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.people,
                    label: 'Total Advocates',
                    value: '${list.length}',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStatItem(
                    icon: Icons.location_city,
                    label: 'Locations',
                    value: '${allLocations.length}',
                  ),
                ],
              ),
            ),

            // Filter Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Speciality Filter
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<AdvocateSpeciality>(
                      value: selectedSpeciality,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Filter by Speciality",
                        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All Specialities"),
                        ),
                        ...AdvocateSpeciality.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(s.icon, size: 18, color: Colors.purple),
                                const SizedBox(width: 8),
                                Text(s.label),
                              ],
                            ),
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
                  const SizedBox(height: 12),

                  // Location Filter
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedLocation,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Filter by Location",
                        labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All Locations"),
                        ),
                        ...allLocations.map(
                          (loc) => DropdownMenuItem(
                            value: loc,
                            child: Row(
                              children: [
                                Icon(Icons.location_on, size: 18, color: Colors.purple),
                                const SizedBox(width: 8),
                                Expanded(child: Text(loc)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedLocation = value);
                        if (value == null) {
                          getAdvocateList();
                        } else {
                          fetchByLocation(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Advocate List
            Expanded(
              child: loading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.purple),
                          SizedBox(height: 16),
                          Text('Loading advocates...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No advocates found',
                                style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try changing your filter criteria',
                                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: getAdvocateList,
                          color: Colors.purple,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final adv = list[index];
                              return _buildAdvocateCard(adv, index);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildAdvocateCard(AdvocateDetailsModel adv, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await NavigationHelper.push(
              context,
              AdvocateDetails(advocateDetailsModel: adv),
              transitionType: _getRandomAnimation(),
              duration: const Duration(milliseconds: 400),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Profile Image with FutureBuilder
                  FutureBuilder<Uint8List?>(
                    future: fetchProfileImage(adv.profileImageId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.purple.shade400, Colors.blue.shade400],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data == null) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.purple.shade400, Colors.blue.shade400],
                            ),
                          ),
                          child: const Icon(Icons.person, size: 30, color: Colors.white),
                        );
                      }

                      return CircleAvatar(
                        radius: 30,
                        backgroundImage: MemoryImage(snapshot.data!),
                        backgroundColor: Colors.transparent,
                      );
                    },
                  ),
                  const SizedBox(width: 16),

                  // Advocate Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adv.name ?? "Unknown Advocate",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Experience: ${adv.experience ?? 0} years",
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Speciality: ${adv.advocateSpeciality.take(2).join(", ")}${adv.advocateSpeciality.length > 2 ? "..." : ""}",
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (adv.locationName != null && adv.locationName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    adv.locationName!,
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Arrow Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.purple),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}