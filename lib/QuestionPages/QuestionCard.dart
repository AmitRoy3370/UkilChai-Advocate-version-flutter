import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as baseURL;
import '../Utils/BaseURL.dart' as BASE_URL;
import 'AnswerModel.dart';
import 'AnswerService.dart';
import 'AnswerTile.dart';
import 'QuestionModel.dart';

class QuestionCard extends StatelessWidget {
  final QuestionModel question;
  const QuestionCard({required this.question, super.key});

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
          "${baseURL.Urls().baseURL}questions/downloadQuestionContent?attachmentId=$attachmentId";

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

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionType,
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 6),
            FutureBuilder<String>(
              future: getNameFromUser(question.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading...");
                }

                return Text(
                  "Asked by ${snapshot.data}",
                  style: const TextStyle(color: Colors.black),
                );

              }
            ),
            const SizedBox(height: 6),
            Text(
              question.message,
              style: const TextStyle(color: Colors.black),
            ),

            if (question.attachmentId != null)
              InkWell(
                onTap: () =>
                    openAttachment(context, question.attachmentId!),
                child: const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "View Attachment",
                    style: TextStyle(
                      color: Colors.green,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

            const Divider(color: Colors.grey),

            /// ================= ANSWERS =================
            FutureBuilder<List<AnswerModel>>(
              future: AnswerService.getByQuestion(question.id!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text(
                    "Loading answers...",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                final answers = snapshot.data!;
                if (answers.isEmpty) {
                  return const Text(
                    "No answers yet",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return Column(
                  children: answers
                      .map((a) => AnswerTile(answer: a))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
