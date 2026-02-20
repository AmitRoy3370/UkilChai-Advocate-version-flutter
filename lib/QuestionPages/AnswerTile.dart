import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as baseURL;
import 'AnswerModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnswerTile extends StatelessWidget {
  final AnswerModel answer;
  const AnswerTile({required this.answer, super.key});

  // ---------------- GET USER NAME ----------------
  Future<String> getNameFromUser(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final url = "${baseURL.Urls().baseURL}user/search?userId=$userId";

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

    final url = "${baseURL.Urls().baseURL}advocate/$advocateId";

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

  String _getExtensionFromContentType(String? contentType) {
    if (contentType == null) return ".bin";

    if (contentType.contains("pdf")) return ".pdf";
    if (contentType.contains("jpeg")) return ".jpeg";
    if (contentType.contains("jpg")) return ".jpg";
    if (contentType.contains("png")) return ".png";
    if (contentType.contains("word")) return ".docx";
    if (contentType.contains("excel")) return ".xlsx";
    if (contentType.contains("text")) return ".txt";

    return ".bin";
  }

  Future<void> openAttachment(BuildContext context, String attachmentId) async {
    try {
      final url =
          "${baseURL.Urls().baseURL}answers/download?attachmentId=$attachmentId";

      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Download failed")));
        return;
      }

      // 🔹 Extract filename from header
      String fileName = "attachment";
      final disposition = response.headers['content-disposition'];
      if (disposition != null) {
        final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
        if (match != null) {
          fileName = match.group(1)!;
        }
      }

      // 🔹 Get content type
      final contentType = response.headers['content-type'] ?? "application/octet-stream";

      // 🔹 Add extension if missing
      if (!fileName.contains(".")) {
        fileName += _getExtensionFromContentType(contentType);
      }

      // ==========================================
      // 🌐 WEB
      // ==========================================
      if (kIsWeb) {
        final blob = html.Blob([response.bodyBytes], contentType);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();

        html.Url.revokeObjectUrl(url);
        return;
      }

      // ==========================================
      // 📱 MOBILE
      // ==========================================
      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/$fileName";

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await OpenFilex.open(filePath);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Attachment error: $e")));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          FutureBuilder<String>(
            future: getNameFromAdvocate(answer.advocateId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Advocate: loading...");
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text("Advocate: N/A");
              } else {
                return Text("Advocate: ${snapshot.data}", style : TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold));
              }
            }
          ),

          Text(
            answer.message,
            style: const TextStyle(color: Colors.black, fontSize: 13),
          ),
          if (answer.attachmentId != null)
            InkWell(
              onTap: () => openAttachment(context, answer.attachmentId!),
              child: const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  "View Attachment",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
