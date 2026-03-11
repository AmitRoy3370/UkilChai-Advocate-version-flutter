import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;
import '../Auth/AuthService.dart';
import '../Utils/AdvocateSpeciality.dart';
import '../Utils/BaseURL.dart' as baseURL;
import '../Utils/BaseURL.dart' as BASE_URL;
import 'AnswerModel.dart';
import 'AnswerService.dart';
import 'AnswerTile.dart';
import 'QuestionModel.dart';
import 'QuestionService.dart';

class QuestionCard extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback refreshMethod;

  const QuestionCard({
    required this.question,
    required this.refreshMethod,
    super.key,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  String currentUserId = "";
  bool isMyQuestion = false;

  PlatformFile? selectedFile; // Unified for web/mobile
  String? fileName;
  String? fileExtension;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true, // Crucial for web
      type: FileType.any,
    );

    if (result == null) return;

    final file = result.files.first;

    setState(() {
      selectedFile = file;
      fileName = file.name;
      fileExtension = file.extension;
    });

    print("file name :- $fileName");

  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString("userId") ?? "";

    setState(() {
      isMyQuestion = currentUserId == widget.question.userId;
    });
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
          "${baseURL.Urls().baseURL}questions/downloadQuestionContent?attachmentId=$attachmentId";

      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Download failed")));
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
      final contentType =
          response.headers['content-type'] ?? "application/octet-stream";

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Attachment error: $e")));
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

  String? getMimeType(String? extension) {
    if (extension == null) return null;
    extension = extension.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  void showEditDialog() {
    TextEditingController messageController = TextEditingController(
      text: widget.question.message,
    );

    String selectedType = widget.question.questionType;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Question"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: "Message"),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedType,
                items: AdvocateSpeciality.values.map((e) {
                  return DropdownMenuItem(value: e.name, child: Text(e.label));
                }).toList(),
                onChanged: (v) {
                  selectedType = v!;
                },
              ),
              ElevatedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text("Choose Attachment"),
              ),

              if (fileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    fileName!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Updating question...."),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          Text("In process...."),
                        ],
                      ),
                    );
                  },
                );

                try {
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt_token') ?? '';

                  final uri = Uri.parse(
                    "${baseURL.Urls().baseURL}questions/update",
                  ); // From your backend endpoint

                  var request = http.MultipartRequest("PUT", uri);
                  request.headers["Authorization"] = "Bearer $token";

                  request.fields["userId"] = widget
                      .question
                      .userId; // Assuming usersId is a typo or same as userId; adjust if needed
                  request.fields["usersId"] = widget
                      .question
                      .userId; // If backend requires both, set accordingly
                  request.fields["message"] = messageController.text.trim();
                  request.fields["questionType"] = selectedType;
                  request.fields["questionId"] = widget.question.id!;
                  if (widget.question.attachmentId != null) {
                    request.fields["attachmentId"] =
                    widget.question.attachmentId!;
                  } else {
                    request.fields["attachmentId"] = "";
                  }

                  if (selectedFile != null) {
                    final mimeTypeStr = getMimeType(fileExtension);
                    http.MediaType? contentType = mimeTypeStr != null
                        ? http.MediaType.parse(mimeTypeStr)
                        : null;

                    if (kIsWeb) {
                      // Web: use bytes
                      if (selectedFile!.bytes != null) {
                        request.files.add(
                          http.MultipartFile.fromBytes(
                            "file",
                            selectedFile!.bytes!,
                            filename: selectedFile!
                                .name, // Critical: sets originalFilename in backend
                            contentType: contentType, // Sets proper MIME
                          ),
                        );
                      }
                    } else {
                      // Mobile: prefer path, fallback to bytes
                      if (selectedFile!.path != null) {
                        request.files.add(
                          await http.MultipartFile.fromPath(
                            "file",
                            selectedFile!.path!,
                            filename: selectedFile!.name, // Critical
                            contentType: contentType,
                          ),
                        );
                      } else if (selectedFile!.bytes != null) {
                        request.files.add(
                          http.MultipartFile.fromBytes(
                            "file",
                            selectedFile!.bytes!,
                            filename: selectedFile!.name,
                            contentType: contentType,
                          ),
                        );
                      }
                    }
                  }

                  final streamedResponse = await request.send();
                  final response = await http.Response.fromStream(
                    streamedResponse,
                  );

                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
                    if (context.mounted)
                      Navigator.pop(context); // close loading

                    if (context.mounted)
                      Navigator.pop(context); // close edit dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Question updated successfully"),
                      ),
                    );

                    widget.refreshMethod();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed: ${response.body}")),
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Update failed: $e")));

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.question.questionType,
                  style: const TextStyle(color: Colors.green),
                ),
                if (isMyQuestion)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: "edit", child: Text("Edit")),
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Delete"),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == "edit") {
                        showEditDialog();
                      }

                      if (value == "delete") {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Deleting question...."),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  const SizedBox(height: 10),
                                  Text("In process...."),
                                ],
                              ),
                            );
                          },
                        );

                        final res = await QuestionService.deleteQuestion(
                          questionId: widget.question.id!,
                          userId: currentUserId,
                        );
                        if (res) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Question deleted successfully"),
                            ),
                          );

                          setState(() {
                            isMyQuestion = false;
                          });

                          widget.refreshMethod.call();

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to delete question"),
                            ),
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      }
                    },
                  ),
              ],
            ),

            const SizedBox(height: 6),
            FutureBuilder<String>(
              future: getNameFromUser(widget.question.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading...");
                }

                return Text(
                  "Asked by ${snapshot.data}",
                  style: const TextStyle(color: Colors.black),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              widget.question.message,
              style: const TextStyle(color: Colors.black),
            ),

            if (widget.question.attachmentId != null)
              InkWell(
                onTap: () =>
                    openAttachment(context, widget.question.attachmentId!),
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
              future: AnswerService.getByQuestion(widget.question.id!),
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
                  children: answers.map((a) => AnswerTile(answer: a)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
