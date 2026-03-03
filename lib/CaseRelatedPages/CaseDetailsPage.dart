import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'case_judgment_service.dart';
import 'CaseJudgmentModel.dart';
import './AppealCasePage.dart';

import './case_model.dart';
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASE_URL;
import 'package:advocatechaiadvocate/Auth/AuthService.dart';

import 'AttachmentViewer.dart';
import 'case_tracking.dart';
import 'edit_case_page.dart';

class CaseDetailsPage extends StatelessWidget {
  final CaseModel caseModel;
  final String? userId;

  CaseDetailsPage({super.key, required this.caseModel, this.userId});

  final String baseUrl = "${BASE_URL.Urls().baseURL}case";

  // ---------------- OPEN ATTACHMENT ----------------
  Future<void> openAttachment(String attachmentId, {bool view = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token') ?? '';

    final url = Uri.parse(
      '${BASE_URL.Urls().baseURL}case/attachment/$attachmentId',
    );
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      // get temp directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$attachmentId');

      await file.writeAsBytes(bytes);

      // open the file
      await OpenFile.open(file.path);
    } else {
      throw Exception('Failed to download attachment: ${response.statusCode}');
    }
  }

  Future<CaseJudgment?> loadJudgment() {
    return CaseJudgmentService.getByCase(caseModel.id);
  }

  Future<bool> isMyCase() async {
    final prefs = await SharedPreferences.getInstance();
    final myUserId = prefs.getString('userId');
    return myUserId != null && myUserId == caseModel.userId;
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

  Future<bool> isMyFightingCase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final advocateId = prefs.getString("advocateId");

    if (advocateId == null) {
      return false;
    }

    return advocateId == caseModel.advocateId;
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
      print("find advocate $advocateId from name from advocate....");

      final body = jsonDecode(response.body);
      final userId = body["userId"];

      print("userId :- $userId");

      return getNameFromUser(userId);
    }
    return "";
  }

  // ---------------- DELETE CASE ----------------
  Future<void> deleteCase(BuildContext context) async {
    final url = "$baseUrl/${caseModel.id}/${caseModel.userId}";

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "content-type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Case deleted successfully")),
        );
        Navigator.pop(context, true);
      } else {
        throw body["error"] ?? "Delete failed";
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Case"),
        content: const Text(
          "Are you sure you want to delete this case?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deleteCase(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ---------------- FUTURE INFO ROW ----------------
  Widget _futureInfo(String title, Future<String> future) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading...");
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Text("N/A");
                }
                return Text(snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- NORMAL INFO ROW ----------------
  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info("Case Name", caseModel.caseName),
                _info("Case Type", caseModel.caseType),

                _futureInfo("User", getNameFromUser(caseModel.userId)),

                _futureInfo(
                  "Advocate",
                  getNameFromAdvocate(caseModel.advocateId),
                ),

                _info("Issued Time", caseModel.issuedTime),

                const SizedBox(height: 16),

                const Text(
                  "Attachments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                if (caseModel.attachmentsId.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text("No attachments available"),
                  ),

                ...caseModel.attachmentsId.map(
                  (id) => ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(id, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () => SharedPreferences.getInstance().then(
                            (prefs) {
                              final token = prefs.getString('jwt_token') ?? '';
                              final userId = prefs.getString('userId') ?? '';

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CaseAttachmentView(
                                    attachmentId: id,
                                    jwtToken: token,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            SharedPreferences.getInstance().then((prefs) {
                              final token = prefs.getString('jwt_token') ?? '';
                              final userId = prefs.getString('userId') ?? '';

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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                FutureBuilder<bool>(
                  future: isMyCase(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(); // no UI jump
                    }

                    if (snapshot.hasData && snapshot.data == true) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text("Delete Case"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => confirmDelete(context),
                        ),
                      );
                    }

                    return const SizedBox(); // hide button if not owner
                  },
                ),
                const SizedBox(height: 16),

                // ==================== REPLACE THIS ENTIRE BUTTON ====================
                ElevatedButton(
                  onPressed: () async {
                    // Show loader immediately
                    showDialog(
                      context: context,
                      barrierDismissible: false, // user can't close it
                      builder: (ctx) => const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  "Loading Case Tracking...\nPlease wait",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                    try {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('jwt_token') ?? '';
                      final userId = prefs.getString('userId') ?? '';

                      // Pre-load everything needed (this was causing the delay)
                      final advocateName = await getNameFromAdvocate(caseModel.advocateId);

                      final nameResponse = await http.get(
                        Uri.parse('${BASE_URL.Urls().baseURL}user/search?userId=$userId'),
                        headers: {
                          "content-type": "application/json",
                          "Authorization": "Bearer $token",
                        },
                      );
                      String? myName = "";
                      if (nameResponse.statusCode == 200) {
                        final body = jsonDecode(nameResponse.body);
                        myName = body["name"] ?? "";
                      }

                      String? advocateUserId;
                      final response = await http.get(
                        Uri.parse("${BASE_URL.Urls().baseURL}advocate/${caseModel.advocateId}"),
                        headers: {
                          "content-type": "application/json",
                          "Authorization": "Bearer $token",
                        },
                      );
                      if (response.statusCode == 200) {
                        final body = jsonDecode(response.body);
                        advocateUserId = body["userId"];
                      }

                      // Close the loader dialog
                      Navigator.pop(context);

                      // Now navigate (page will open instantly because data is ready)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CaseTracking(
                            caseId: caseModel.id,
                            caseName: caseModel.caseName,
                            caseLawyer: advocateName,
                            issuedTime: caseModel.issuedTime,
                            token: token,
                            advocateUserId: advocateUserId,
                            userName: myName,
                            userId: caseModel.userId == userId ? userId : null,
                            advocateId: caseModel.advocateId,
                          ),
                        ),
                      );
                    } catch (e) {
                      // Close loader if error
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error loading tracking: $e")),
                      );
                    }
                  },
                  child: const Text("Case Tracking"),
                ),
// ===================================================================

                FutureBuilder<bool>(
                  future: isMyCase(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(); // no UI jump
                    }

                    if (snapshot.hasData && snapshot.data == true) {
                      return SizedBox(
                        width: double.infinity,
                        child: FutureBuilder<CaseJudgment?>(
                          future: loadJudgment(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) {
                              return const SizedBox();
                            }

                            final judgment = snapshot.data!;

                            final today = DateTime.now();
                            final judgmentDate = judgment.date;

                            final canAppeal = judgmentDate.isBefore(
                              DateTime(today.year, today.month, today.day),
                            );

                            if (!canAppeal) return const SizedBox();

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.gavel),
                                label: const Text("Case Appeal"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () async {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  final token =
                                      prefs.getString('jwt_token') ?? '';
                                  final userId =
                                      prefs.getString('userId') ?? '';

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AppealCasePage(
                                        token: token,
                                        caseId: caseModel.id,
                                        userId: userId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox(); // hide button if not owner
                  },
                ),

                const SizedBox(height: 16),

                FutureBuilder<bool>(
                  future: isMyFightingCase(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(); // no UI jump
                    }
                    if (snapshot.hasData && snapshot.data == true) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            final token = prefs.getString('jwt_token') ?? '';

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditCasePage(
                                  token: token,
                                  acceptedCase: caseModel,
                                ),
                              ),
                            );
                          },
                          child: Text("Update Case"),
                        ),
                      );
                    } else {
                      return const SizedBox(); // hide button if not owner
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
