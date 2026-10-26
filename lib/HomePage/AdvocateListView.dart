// HomePage/AdvocateListView.dart
import 'dart:convert';
import '../AdvocatePages/AdvocateDetailsModel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Utils/BaseURL.dart' as baseURL;
import '../PageTransition.dart';
import '../Auth/AuthService.dart';
import '../CaseRelatedPages/AddCaseRequestPage.dart';
import '../AdvocatePages/AdvocateDetails.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../RegistrationPage/gender.dart';
import 'AdvocateFilter.dart';
import '../LogInPage/LogIn.dart';


class AdvocateListView extends StatefulWidget {
  final AdvocateFilter? filter;
  final int crossAxisCount;
  final bool showAll;
  final String? speciality; // Backward compatibility
  
  const AdvocateListView({
    super.key,
    this.filter,
    this.crossAxisCount = 2,
    this.showAll = false,
    this.speciality,
  });

  @override
  State<AdvocateListView> createState() => _AdvocateListViewState();
  
  static Future<List<AdvocateDetailsModel>> getAdvocateList({
    AdvocateFilter? filter,
    String? speciality,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      // Build URL based on filters
      String url;
      Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };
      
      // Use speciality from filter or parameter
      final effectiveSpeciality = filter?.speciality ?? speciality;
      
      // If gender is selected, use gender endpoint first
      if (filter?.gender != null) {
        url = "${baseURL.Urls().baseURL}advocate/findByGender/${filter!.gender!.name}";
      }
      // If speciality is selected, use speciality endpoint
      else if (effectiveSpeciality != null && 
               effectiveSpeciality.isNotEmpty && 
               effectiveSpeciality != 'null' && 
               effectiveSpeciality != 'All Specialities') {
        url = "${baseURL.Urls().baseURL}advocate/search/speciality/$effectiveSpeciality";
      }
      // Otherwise get all
      else {
        url = "${baseURL.Urls().baseURL}advocate/all";
      }
      
      print("📡 Fetching advocates from: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print("📊 Response status: ${response.statusCode}");
      
      if (response.statusCode != 200) {
        print("❌ Error response: ${response.body}");
        throw Exception("Failed to load advocates: ${response.statusCode}");
      }
      
      final List responseData = jsonDecode(response.body);
      print("📊 Found ${responseData.length} advocates");
      
      List<AdvocateDetailsModel> list = [];
      
      for (var item in responseData) {
        try {
          final advocateDecoded = item as Map<String, dynamic>;
          
          // Parse gender from response
          Gender? gender;
          if (advocateDecoded['gender'] != null) {
            final genderStr = advocateDecoded['gender'].toString().toUpperCase();
            switch (genderStr) {
              case 'MALE': gender = Gender.MALE; break;
              case 'FEMALE': gender = Gender.FEMALE; break;
              case 'OTHER': gender = Gender.OTHER; break;
            }
          }
          
          final model = AdvocateDetailsModel.defaultConstructor()
            ..id = advocateDecoded["id"]?.toString()
            ..userId = advocateDecoded["userId"]?.toString()
            ..name = advocateDecoded["name"]?.toString()
            ..fullName = advocateDecoded["fullName"]?.toString()
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
            ..email = advocateDecoded["email"]?.toString()
            ..phone = advocateDecoded["phone"]?.toString()
            ..locationName = advocateDecoded["locationName"]?.toString()
            ..lattitude = advocateDecoded["lattitude"] != null 
                ? double.tryParse(advocateDecoded["lattitude"].toString()) 
                : null
            ..longitude = advocateDecoded["longitude"] != null 
                ? double.tryParse(advocateDecoded["longitude"].toString()) 
                : null
            ..contactInfoId = advocateDecoded['contactInfoId']?.toString()
            ..locationId = advocateDecoded['locationId']?.toString()
            ..cvHexKey = advocateDecoded['cvHexKey']?.toString()
            ..district = advocateDecoded['district']?.toString()
            ..rating = advocateDecoded['rating'] != null 
                ? double.tryParse(advocateDecoded['rating'].toString()) ?? 0.0 
                : 0.0
            ..userGenderId = advocateDecoded['userGenderId']?.toString()
            ..gender = gender;
          
          list.add(model);
        } catch (e) {
          print("⚠️ Error parsing advocate: $e");
        }
      }
      
      // Apply location filter locally if needed
      // Apply location filter locally if needed
if (filter?.location != null && filter!.location!.isNotEmpty) {
  final locationFilter = filter.location!; // Extract to a non-nullable variable
  list = list.where((adv) => 
    (adv.district != null && adv.district!.contains(locationFilter)) || 
    (adv.locationName != null && adv.locationName!.contains(locationFilter))
  ).toList();
  print("📍 Filtered by location: ${list.length} advocates found");
}
      
      return list;
    } catch (e) {
      print("❌ Error in getAdvocateList: $e");
      return [];
    }
  }
}

class _AdvocateListViewState extends State<AdvocateListView> {
  List<AdvocateDetailsModel> _advocates = [];
  bool _isLoading = true;
  String? _error;
  
  final Map<String, Uint8List?> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _loadAdvocates();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(AdvocateListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if filter or speciality changed
    if (oldWidget.filter != widget.filter || oldWidget.speciality != widget.speciality) {
      print("🔄 Filter changed: ${widget.filter}");
      _imageCache.clear();
      _loadAdvocates();
    }
  }

  Future<void> _loadAdvocates() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final advocates = await AdvocateListView.getAdvocateList(
        filter: widget.filter,
        speciality: widget.speciality,
      );
      if (mounted) {
        setState(() {
          _advocates = advocates;
          _isLoading = false;
        });
        print("✅ Loaded ${advocates.length} advocates");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        print("❌ Error loading advocates: $e");
      }
    }
  }

  Future<Uint8List?> fetchProfileImage(String? imageId) async {
    if (imageId == null || imageId.isEmpty) {
      return null;
    }
    
    if (_imageCache.containsKey(imageId)) {
      return _imageCache[imageId];
    }

    try {
      final token = await AuthService.getToken();
      final url = Uri.parse("${baseURL.Urls().baseURL}user/download/$imageId");
      
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        _imageCache[imageId] = bytes;
        return bytes;
      } else {
        print("❌ Failed to load image: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error loading image: $e");
    }
    _imageCache[imageId] = null;
    return null;
  }

  Future<void> _navigateToDetails(BuildContext context, AdvocateDetailsModel advocate) async {
    NavigationHelper.push(
      context,
      AdvocateDetails(advocateDetailsModel: advocate),
      transitionType: await AnimatedRoute.getRandomSafeAnimation(),
      duration: const Duration(milliseconds: 600),
      curve: Curves.bounceOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isTablet = screenWidth > 600 && screenWidth <= 800;
    
    int crossAxisCount = widget.crossAxisCount;
    if (isDesktop) {
      crossAxisCount = 4;
    } else if (isTablet) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }
    
    if (_isLoading) {
      return SizedBox(
        height: widget.showAll ? 400 : 280,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: 2,
              ),
              SizedBox(height: 10),
              Text(
                "Loading advocates...",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadAdvocates,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_advocates.isEmpty) {
      // Get display text for empty state
      String emptyMessage = "No advocates found";
      String subMessage = "";
      
      if (widget.filter?.speciality != null && widget.filter!.speciality!.isNotEmpty) {
        subMessage = "for ${widget.filter!.speciality}";
      } else if (widget.speciality != null && widget.speciality!.isNotEmpty) {
        subMessage = "for ${widget.speciality}";
      }
      
      if (widget.filter?.location != null && widget.filter!.location!.isNotEmpty) {
        subMessage = subMessage.isEmpty 
            ? "in ${widget.filter!.location}" 
            : "$subMessage in ${widget.filter!.location}";
      }
      
      if (widget.filter?.gender != null) {
        final genderName = widget.filter!.gender!.name;
        subMessage = subMessage.isEmpty 
            ? "with ${genderName.toLowerCase()} gender" 
            : "$subMessage with ${genderName.toLowerCase()} gender";
      }
      
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 40,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                emptyMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final int itemCount = widget.showAll 
        ? _advocates.length 
        : (_advocates.length > 6 ? 6 : _advocates.length);

    double aspectRatio;
    if (isDesktop) {
      aspectRatio = 0.75;
    } else if (isTablet) {
      aspectRatio = 0.70;
    } else {
      aspectRatio = 0.65;
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final AdvocateDetailsModel advocate = _advocates[index];

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () async {
      final token = await AuthService.getToken();
      if(token == null) {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const LogIn()),);
      } else {
                _navigateToDetails(context, advocate);

              }
              },
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double imageHeight = constraints.maxWidth * 0.85;
                      if (imageHeight < 100) imageHeight = 100;
                      if (imageHeight > 180) imageHeight = 180;
                      
                      return Container(
                        width: double.infinity,
                        height: imageHeight,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.shade100,
                              Colors.blue.shade100,
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: FutureBuilder<Uint8List?>(
                            key: ValueKey(advocate.profileImageId ?? 'no_image_$index'),
                            future: fetchProfileImage(advocate.profileImageId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                  ),
                                );
                              }
                              
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.memory(
                                  snapshot.data!,
                                  width: double.infinity,
                                  height: imageHeight,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                );
                              }
                              
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "No Image",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Name and Info
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Name with Gender Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                advocate.fullName ?? advocate.name ?? "Unknown",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Gender Badge
                            if (advocate.gender != null)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _getGenderColor(advocate.gender!).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getGenderIcon(advocate.gender!),
                                      size: 10,
                                      color: _getGenderColor(advocate.gender!),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 2),
                        
                        if (advocate.district != null && advocate.district!.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.grey.shade500,
                                size: 11,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  advocate.district!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        
                        const SizedBox(height: 3),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Rating
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade400,
                                    Colors.amber.shade600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    advocate.rating.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 4),
                            
                            // Experience
                            if (advocate.experience != null && advocate.experience! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.work_outline,
                                      size: 10,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${advocate.experience}y",
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Case Request Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                          shadowColor: Colors.green.shade300.withOpacity(0.4),
                          textStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('userId') ?? '';

      final token = await AuthService.getToken();
      if(token == null) {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const LogIn()),);
      } else {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddCaseRequestPage(
                                userId: userId,
                                specialRequestedAdvocate: advocate.id,
                              ),
                            ),
                          );
                        }

                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gavel,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Request Case",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Helper methods for gender
  Color _getGenderColor(Gender gender) {
    switch (gender) {
      case Gender.MALE:
        return Colors.blue;
      case Gender.FEMALE:
        return Colors.pink;
      case Gender.OTHER:
        return Colors.purple;
    }
  }
  
  IconData _getGenderIcon(Gender gender) {
    switch (gender) {
      case Gender.MALE:
        return Icons.male;
      case Gender.FEMALE:
        return Icons.female;
      case Gender.OTHER:
        return Icons.transgender;
    }
  }
}