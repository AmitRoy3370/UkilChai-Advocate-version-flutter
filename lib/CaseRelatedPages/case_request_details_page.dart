import 'dart:convert';

import 'package:advocatechaiadvocate/Auth/AuthService.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/CaseRequestAttachmentViewer.dart';
import 'package:advocatechaiadvocate/Utils/AdvocateSpeciality.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './case_request.dart';
import './case_request_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class CaseRequestDetailsPage extends StatelessWidget {
  final CaseRequest caseRequest;
  final service = CaseRequestService();

  CaseRequestDetailsPage({super.key, required this.caseRequest});

  void openAttachment(String id) {
    launchUrl(
      Uri.parse("${BASE_URL.Urls().baseURL}case-request/attachment/view/$id"),
      mode: LaunchMode.externalApplication,
    );
  }

  // Get the advocate name
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

  Future<String?> advocateId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? advocateId = prefs.getString('advocateId');
    return advocateId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case Details")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Text("Case Description", style: Theme.of(context).textTheme.titleMedium),
            Text(caseRequest.caseName),
            const Divider(),

            Text("Case Type"),
            Chip(label: Text(caseRequest.caseType.label)),
            const Divider(),

            Text("Requested By"),

            Text(caseRequest.userName, style: TextStyle(fontWeight: FontWeight.bold),),

            const Divider(),

            if (caseRequest.requestedAdvocateId != null)
              Text("Requested Advocate: ${caseRequest.requestAdvocateName}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),

            const Divider(),

            Text("Attachments"),
            caseRequest.attachmentId.isEmpty
                ? const Text("No attachments")
                : Column(
                    children: caseRequest.attachmentId.map((id) {
                      return ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(id),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            String jwtToken =
                                prefs.getString('jwt_token') ?? '';

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CaseRequestAttachmentViewer(
                                  attachmentId: id,
                                  jwtToken: jwtToken,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 20),

            FutureBuilder<String?>(
              future: advocateId(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading...");
                }

                if (caseRequest.requestedAdvocateId == null ||
                    caseRequest.requestedAdvocateId == snapshot.data) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Accept Case"),
                    onPressed: () async {
                      // pass logged-in advocate userId

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Accepting case..."),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  "Please wait while we are accepting this case...",
                                ),
                                SizedBox(height: 8),
                                Text("This may take a few seconds..."),
                              ],
                            ),
                          );
                        },
                      );

                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();

                      String? userId = prefs.getString('userId');

                      bool response = await service.acceptCase(
                        caseRequest.id,
                        userId!,
                      );

                      // Close loading dialog - ONLY POP ONCE
                      if (context.mounted) {
                        Navigator.pop(context); // Close loading dialog
                      }

                      if (response) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Case is accepted successfully..."),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Pop the details page with true result
                          Navigator.pop(context, true);
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Case is not accepted....."),
                              backgroundColor: Colors.red,
                            ),
                          );
                          // Stay on details page if failed
                          Navigator.pop(context, true);
                        }
                      }

                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }

                      Navigator.pop(context, true);
                    },
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
