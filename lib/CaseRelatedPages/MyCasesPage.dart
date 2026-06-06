import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './case_model.dart';
import 'CaseDetailsPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/AttachmentViewer.dart';
import '../PageTransition.dart';

class MyCasesPage extends StatefulWidget {
  final String userId;

  const MyCasesPage({super.key, required this.userId});

  @override
  State<MyCasesPage> createState() => _MyCasesPageState();
}

class _MyCasesPageState extends State<MyCasesPage>
    with SingleTickerProviderStateMixin {
  late Future<List<CaseModel>> futureCases;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final String baseUrl = "${BASE_URL.Urls().baseURL}case";

  // List of available transition types for random selection
  final List<PageTransitionType> _transitionTypes =
      AnimatedRoute.getCompanySafeAnimations();

  @override
  void initState() {
    super.initState();
    futureCases = fetchMyCases();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Get random transition type
  PageTransitionType _getRandomTransition() {
    final random =
        DateTime.now().millisecondsSinceEpoch % _transitionTypes.length;
    return _transitionTypes[random];
  }

  // Navigate with random transition
  void _navigateWithRandomTransition(BuildContext context, Widget page) {
    NavigationHelper.push(
      context,
      page,
      transitionType: _getRandomTransition(),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Future<List<CaseModel>> fetchMyCases() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('jwt_token') ?? '';

    final response = await http.get(
      Uri.parse("$baseUrl/user/${widget.userId}"),
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List list = decoded["data"];

      late List caseList = list.reversed.toList();

      return caseList.map((e) => CaseModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load cases");
    }
  }

  Future<void> openAttachment(String attachmentId, {bool view = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final url = view
        ? "$baseUrl/attachment/view/$attachmentId"
        : "$baseUrl/attachment/$attachmentId";

    if (kIsWeb) {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open file")));
      }
      return;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/$attachmentId";
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      await OpenFilex.open(filePath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unauthorized or file not found")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "My Cases",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E), // Deep Navy
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E), // Deep Navy
                Color(0xFF283593), // Indigo
                Color(0xFF3949AB), // Lighter Indigo
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder<List<CaseModel>>(
          future: futureCases,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Loading your cases..."),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              );
            }

            final cases = snapshot.data!;

            if (cases.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No cases found",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your cases will appear here",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  futureCases = fetchMyCases();
                });
              },
              color: Colors.deepPurple,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final c = cases[index];
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    curve: Curves.easeOutCubic,
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: _buildCaseCard(c, index),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCaseCard(CaseModel c, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('jwt_token') ?? '';
            final userId = prefs.getString('userId') ?? '';

            _navigateWithRandomTransition(
              context,
              CaseDetailsPage(
                caseModel: c,
                userId: userId,
                onDeleted: () {
                  setState(() {
                    futureCases = fetchMyCases();
                  });
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.deepPurple.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Case Name
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.caseName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: Text(
                          "ACTIVE",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Case Type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category,
                          size: 16,
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Case Type: ${c.caseType}",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Advocate Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Advocate: ${c.advocateName ?? "Not Assigned"}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // User Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Client: ${c.userName}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Issued Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Issued: ${c.issuedTime}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  // Attachments Section
                  if (c.attachmentsId.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.attachment,
                          size: 16,
                          color: Colors.deepPurple.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Attachments (${c.attachmentsId.length})",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: c.attachmentsId.map((id) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.visibility,
                                  size: 18,
                                  color: Colors.deepPurple.shade600,
                                ),
                                onPressed: () {
                                  SharedPreferences.getInstance().then((prefs) {
                                    final token =
                                        prefs.getString('jwt_token') ?? '';
                                    _navigateWithRandomTransition(
                                      context,
                                      CaseAttachmentView(
                                        attachmentId: id,
                                        jwtToken: token,
                                      ),
                                    );
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.download,
                                  size: 18,
                                  color: Colors.deepPurple.shade600,
                                ),
                                onPressed: () {
                                  SharedPreferences.getInstance().then((prefs) {
                                    final token =
                                        prefs.getString('jwt_token') ?? '';
                                    _navigateWithRandomTransition(
                                      context,
                                      CaseAttachmentView(
                                        attachmentId: id,
                                        jwtToken: token,
                                      ),
                                    );
                                  });
                                },
                              ),
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 120,
                                ),
                                child: Text(
                                  id.length > 20
                                      ? '${id.substring(0, 17)}...'
                                      : id,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // View Details Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1A237E), // Deep Navy
                          Color(0xFF283593), // Indigo
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        final token = prefs.getString('jwt_token') ?? '';
                        final userId = prefs.getString('userId') ?? '';

                        _navigateWithRandomTransition(
                          context,
                          CaseDetailsPage(
                            caseModel: c,
                            userId: userId,
                            onDeleted: () {
                              setState(() {
                                futureCases = fetchMyCases();
                              });
                            },
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "View Details",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
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
