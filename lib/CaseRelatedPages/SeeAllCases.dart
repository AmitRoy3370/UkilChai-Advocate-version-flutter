import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './case_model.dart';
import 'CaseDetailsPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/AttachmentViewer.dart';
import '../PageTransition.dart';

class SeeAllCasesPage extends StatefulWidget {
  const SeeAllCasesPage({super.key});

  @override
  State<SeeAllCasesPage> createState() => _SeeAllCasesPageState();
}

class _SeeAllCasesPageState extends State<SeeAllCasesPage> {
  late Future<List<CaseModel>> futureCases;
  final String baseUrl = "${BASE_URL.Urls().baseURL}case";

  @override
  void initState() {
    super.initState();
    futureCases = fetchMyCases();
  }

  Future<String> getNameFromUser(String userId) async {
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

  Future<String> getNameFromAdvocate(String advocateId) async {
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

  Future<List<CaseModel>> fetchMyCases() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('jwt_token') ?? '';
    final response = await http.get(
      Uri.parse("$baseUrl/all"),
      headers: {"content-type": "application/json", "Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List list = decoded["data"];
      // Reverse to show last case first
      return list.map((e) => CaseModel.fromJson(e)).toList().reversed.toList();
    } else {
      throw Exception("Failed to load cases");
    }
  }

  Future<void> openAttachment(String attachmentId, {bool view = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final url = view ? "$baseUrl/attachment/view/$attachmentId" : "$baseUrl/attachment/$attachmentId";

    if (kIsWeb) {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open file")),
        );
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "My Cases",
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<CaseModel>>(
        future: futureCases,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 16),
                  Text('Loading cases...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.inter(color: Colors.grey[600]),
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
                  Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No cases found',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
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
            color: Colors.purple,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final c = cases[index];
                return _buildCaseCard(c);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaseCard(CaseModel c) {
    final hasAttachments = c.attachmentsId.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('jwt_token') ?? '';
            final userId = prefs.getString('userId') ?? '';

            final result = await NavigationHelper.push(
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
              transitionType: await AnimatedRoute.getRandomSafeAnimation(),
              duration: const Duration(milliseconds: 400),
            );

            if (result == true) {
              setState(() {
                futureCases = fetchMyCases();
              });
            }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Type Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.purple.shade400, Colors.blue.shade400],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCaseIcon(c.caseType),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Text(
                              "Type: ${c.caseType}",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Advocate and User Info
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Advocate: ${c.advocateName}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'User: ${c.userName}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Issued: ${c.issuedTime}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Attachments Section
                  if (hasAttachments) ...[
                    const Divider(color: Colors.grey, height: 8),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_file, size: 14, color: Colors.purple),
                        const SizedBox(width: 6),
                        Text(
                          'Attachments (${c.attachmentsId.length})',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
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
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.visibility, size: 18, color: Colors.blue),
                                onPressed: () {
                                  SharedPreferences.getInstance().then((prefs) {
                                    final token = prefs.getString('jwt_token') ?? '';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CaseAttachmentView(
                                          attachmentId: id,
                                          jwtToken: token,
                                        ),
                                      ),
                                    );
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: Icon(Icons.download, size: 18, color: Colors.green),
                                onPressed: () => openAttachment(id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  id.substring(0, id.length > 8 ? 8 : id.length),
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCaseIcon(String caseType) {
    final type = caseType.toLowerCase();
    if (type.contains('criminal')) return Icons.gavel;
    if (type.contains('family')) return Icons.family_restroom;
    if (type.contains('corporate')) return Icons.business_center;
    if (type.contains('property')) return Icons.home_work;
    if (type.contains('cyber')) return Icons.computer;
    if (type.contains('labour')) return Icons.work;
    if (type.contains('tax')) return Icons.receipt;
    return Icons.description;
  }
}