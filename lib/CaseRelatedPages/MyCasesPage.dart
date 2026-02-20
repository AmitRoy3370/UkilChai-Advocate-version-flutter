import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
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

class MyCasesPage extends StatefulWidget {
  final String userId;

  const MyCasesPage({super.key, required this.userId});

  @override
  State<MyCasesPage> createState() => _MyCasesPageState();
}

class _MyCasesPageState extends State<MyCasesPage> {
  late Future<List<CaseModel>> futureCases;

  final String baseUrl = "${BASE_URL.Urls().baseURL}case";

  @override
  void initState() {
    super.initState();
    futureCases = fetchMyCases();
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

  // ---------------- GET ADVOCATE NAME ----------------
  Future<String> getNameFromAdvocate(String advocateId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final url = "${BASE_URL.Urls().baseURL}advocate/$advocateId";

    print("token from name of advocate :- $token");

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      print("find advocate ${advocateId} from name from advocate....");

      final body = jsonDecode(response.body);
      final userId = body["userId"];

      print("userId :- ${userId}");

      return getNameFromUser(userId);
    }
    return "";
  }

  Future<List<CaseModel>> fetchMyCases() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //String userId = prefs.getString('userId') ?? '';
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

      return list.map((e) => CaseModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load cases");
    }
  }

  // ---------------- DOWNLOAD & OPEN ATTACHMENT ----------------
  Future<void> openAttachment(String attachmentId, {bool view = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final url = view
        ? "$baseUrl/attachment/view/$attachmentId"
        : "$baseUrl/attachment/$attachmentId";

    // ------------------ FLUTTER WEB ------------------
    if (kIsWeb) {
      final uri = Uri.parse(url);

      // JWT-secured download on web must open in new tab
      // Browser will send cookies / headers handled by backend auth
      if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open file")));
      }
      return;
    }

    // ------------------ MOBILE (Android / iOS) ------------------
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
      appBar: AppBar(title: const Text("My Cases")),
      body: FutureBuilder<List<CaseModel>>(
        future: futureCases,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final cases = snapshot.data!;

          if (cases.isEmpty) {
            return const Center(child: Text("No cases found"));
          }

          return ListView.builder(
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final c = cases[index];

              return InkWell(
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt_token') ?? '';
                  final userId = prefs.getString('userId') ?? '';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CaseDetailsPage(caseModel: c, userId: userId),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.caseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("Type: ${c.caseType}"),
                        FutureBuilder<String>(
                          future: getNameFromAdvocate(c.advocateId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text("Advocate: loading...");
                            }

                            if (snapshot.hasError ||
                                !snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Text("Advocate: N/A");
                            }

                            return Text("Advocate: ${snapshot.data}");
                          },
                        ),

                        Text("Issued: ${c.issuedTime}"),

                        const SizedBox(height: 10),

                        if (c.attachmentsId.isNotEmpty)
                          const Text(
                            "Attachments",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                        ...c.attachmentsId.map(
                          (id) => Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () {
                                  SharedPreferences.getInstance().then((prefs) {
                                    final token =
                                        prefs.getString('jwt_token') ?? '';
                                    final userId =
                                        prefs.getString('userId') ?? '';

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
                              ),
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () => SharedPreferences.getInstance().then((prefs) {
                                  final token = prefs.getString('jwt_token') ?? '';
                                  final userId = prefs.getString('userId') ?? '';

                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CaseAttachmentView(
                                          attachmentId: id,
                                          jwtToken: token,
                                        ),
                                      )
                                  );

                                }),
                              ),

                              Expanded(
                                child: Text(
                                  id,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
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
          );
        },
      ),
    );
  }
}
