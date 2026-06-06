import 'dart:convert';
import 'dart:math';
import 'package:advocatechaiadvocate/Auth/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './case_request.dart';
import './case_request_service.dart';
import './case_request_details_page.dart';
import '../Utils/AdvocateSpeciality.dart';
import '../PageTransition.dart';

Future<String> getAdvocateName(String advocateId) async {
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

Future<String> getNameFromUser(String userId) async {
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

class SeeMyRequestedCaseToFightListPage extends StatefulWidget {
  const SeeMyRequestedCaseToFightListPage({super.key});

  @override
  State<SeeMyRequestedCaseToFightListPage> createState() =>
      _SeeMyRequestedCaseToFightListPageState();
}

class _SeeMyRequestedCaseToFightListPageState
    extends State<SeeMyRequestedCaseToFightListPage> {
  final service = CaseRequestService();
  List<CaseRequest> list = [];
  bool loading = true;
  final searchCtrl = TextEditingController();
  
  final List<PageTransitionType> _animations = AnimatedRoute.getCompanySafeAnimations();
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? advocateId = prefs.getString('advocateId');
    list = await service.byRequestedAdvocate(advocateId!);
    setState(() => loading = false);
  }

  Future<void> _searchCases(String query) async {
    if (query.isEmpty) {
      await loadAll();
      return;
    }
    setState(() => loading = true);
    list = await service.searchByName(query);
    setState(() => loading = false);
  }

  Future<void> _navigateToDetails(CaseRequest caseRequest) async {
    final transitionType = _animations[_random.nextInt(_animations.length)];
    
    final result = await NavigationHelper.push(
      context,
      CaseRequestDetailsPage(caseRequest: caseRequest),
      transitionType: transitionType,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );

    if (result == true) {
      await loadAll();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return "${date.day}/${date.month}/${date.year}";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }

  Color _getTypeColor(AdvocateSpeciality type) {
    switch (type) {
      case AdvocateSpeciality.CRIMINAL_LAWYER:
        return Colors.red;
      case AdvocateSpeciality.CIVIL_LAWYER:
        return Colors.blue;
      case AdvocateSpeciality.FAMILY_LAWYER:
        return Colors.orange;
      case AdvocateSpeciality.CORPORATE_LAWYER:
        return Colors.deepPurple;
      case AdvocateSpeciality.CYBER_CRIME_LAWYER:
        return Colors.cyan;
      case AdvocateSpeciality.PROPERTY_LAWYER:
        return Colors.green;
      case AdvocateSpeciality.INTELLECTUAL_PROPERTY_LAWYER:
        return Colors.indigo;
      case AdvocateSpeciality.TAX_LAWYER:
        return Colors.teal;
      case AdvocateSpeciality.LABOR_LAWYER:
        return Colors.brown;
      case AdvocateSpeciality.TRADE_LAWYER:
        return Colors.amber;
      case AdvocateSpeciality.BANKING_LAWYER:
        return Colors.lightBlue;
      case AdvocateSpeciality.INSURANCE_LAWYER:
        return Colors.pink;
      case AdvocateSpeciality.WOMEN_AND_CHILD_RIGHTS_LAWYER:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Cases to Fight",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF1A237E),
                Color(0xFF283593),
                Color(0xFF3949AB),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchCtrl,
              style: GoogleFonts.inter(color: Colors.grey[800]),
              decoration: InputDecoration(
                hintText: "Search case by name...",
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: const Color(0xFF1A237E)),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () {
                          searchCtrl.clear();
                          _searchCases('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _searchCases(value);
              },
            ),
          ),
          
          // Count Badge
          if (!loading && list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF1A237E), const Color(0xFF283593)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${list.length} ${list.length == 1 ? 'Case' : 'Cases'}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Tap to view details",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // List View
          Expanded(
            child: loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF1A237E)),
                        const SizedBox(height: 16),
                        Text(
                          "Loading cases...",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.gavel,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchCtrl.text.isEmpty
                                  ? "No cases to fight"
                                  : "No matching cases",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchCtrl.text.isEmpty
                                  ? "When advocates request your cases, they'll appear here"
                                  : "Try a different search term",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadAll,
                        color: const Color(0xFF1A237E),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: list.length,
                          itemBuilder: (_, index) {
                            final c = list[index];
                            return TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: Duration(milliseconds: 400 + (index * 50)),
                              curve: Curves.easeOutCubic,
                              builder: (context, double value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: GestureDetector(
                                onTap: () => _navigateToDetails(c),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top colored bar based on case type
                                      Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _getTypeColor(c.caseType),
                                              _getTypeColor(c.caseType).withOpacity(0.6),
                                            ],
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Case Name and Type
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    c.caseName,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[800],
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        _getTypeColor(c.caseType),
                                                        _getTypeColor(c.caseType).withOpacity(0.7),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    c.caseType.label.split(' ').first,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                            // User Info
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF1A237E).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(
                                                    Icons.person_outline,
                                                    size: 16,
                                                    color: Color(0xFF1A237E),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    c.userName,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),

                                            // Advocate Info (if assigned)
                                            if (c.requestAdvocateName != null && c.requestAdvocateName!.isNotEmpty)
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Icon(
                                                      Icons.verified,
                                                      size: 16,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      c.requestAdvocateName!,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(height: 12),

                                            // Date and Status Row
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 12,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _formatDate(c.requestDate),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.sports_mma,
                                                        size: 10,
                                                        color: Colors.amber[700],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "Pending",
                                                        style: GoogleFonts.inter(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.amber[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 12),

                                            // View Details Button
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "View Details",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: const Color(0xFF1A237E),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.arrow_forward,
                                                    size: 14,
                                                    color: const Color(0xFF1A237E),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}