import 'dart:convert';
import 'dart:math';
import 'package:advocatechaiadvocate/Auth/AuthService.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './case_request.dart';
import './case_request_service.dart';
import './case_request_details_page.dart';
import '../Utils/AdvocateSpeciality.dart';
import '../PageTransition.dart';  // Make sure this import exists

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

// ---------------- GET USER NAME ----------------
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

class CaseRequestListPage extends StatefulWidget {
  const CaseRequestListPage({super.key});

  @override
  State<CaseRequestListPage> createState() => _CaseRequestListPageState();
}

class _CaseRequestListPageState extends State<CaseRequestListPage> {
  final service = CaseRequestService();
  List<CaseRequest> list = [];
  bool loading = true;
  final searchCtrl = TextEditingController();

  // Only smooth animations - no flip/mirror effects
  final List<PageTransitionType> _smoothAnimations = AnimatedRoute.getCompanySafeAnimations();

  PageTransitionType _getRandomAnimation() {
    final random = Random().nextInt(_smoothAnimations.length);
    return _smoothAnimations[random];
  }

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);
    list = await service.getAll();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Case Requests",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[600]),
            onPressed: loadAll,
          ),
        ],
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
                  Colors.purple.shade600,
                  Colors.blue.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.folder_open,
                  label: 'Total',
                  value: '${list.length}',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                  icon: Icons.verified_user,
                  label: 'Assigned',
                  value: '${list.where((c) => c.requestedAdvocateId != null).length}',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem(
                  icon: Icons.pending,
                  label: 'Pending',
                  value: '${list.where((c) => c.requestedAdvocateId == null).length}',
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
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
              child: TextField(
                controller: searchCtrl,
                style: GoogleFonts.inter(color: Colors.grey[800]),
                decoration: InputDecoration(
                  hintText: "Search case by name or type...",
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.purple),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (v) async {
                  setState(() => loading = true);
                  list = await service.searchByName(v);
                  setState(() => loading = false);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Case List
          Expanded(
            child: loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.purple),
                        SizedBox(height: 16),
                        Text(
                          'Loading cases...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchCtrl.text.isEmpty
                                  ? 'No cases found'
                                  : 'No matching cases',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchCtrl.text.isEmpty
                                  ? 'Submit a new case request'
                                  : 'Try a different search term',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadAll,
                        color: Colors.purple,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (_, index) {
                            final c = list[index];
                            return _buildCaseCard(c, index);
                          },
                        ),
                      ),
          ),
        ],
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
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildCaseCard(CaseRequest c, int index) {
    final bool hasAdvocate = c.requestedAdvocateId != null;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Use NavigationHelper.push with random animation
            await NavigationHelper.push(
              context,
              CaseRequestDetailsPage(caseRequest: c),
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
                  // Icon Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      c.caseType.icon,
                      color: Colors.purple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content Section - ALL INFO HERE
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Case Name
                        Text(
                          c.caseName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // Case Type
                        Text(
                          c.caseType.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.purple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // User Name and Date Row
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                c.userName,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(c.requestDate),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        
                        // Assigned Advocate (if exists)
                        if (hasAdvocate && c.requestAdvocateName != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.verified,
                                size: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Requested Advocate: ${c.requestAdvocateName}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // Attachments Info
                        if (c.attachmentId.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${c.attachmentId.length} attachment${c.attachmentId.length > 1 ? 's' : ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Badge and Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hasAdvocate
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hasAdvocate ? 'ASSIGNED' : 'PENDING',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: hasAdvocate ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.requestDate.toLocal().toString().split(" ").first,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}