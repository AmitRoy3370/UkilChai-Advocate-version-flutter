import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this for MediaType
import 'package:shared_preferences/shared_preferences.dart'; // For token
import 'package:file_picker/file_picker.dart';

import '../Utils/AdvocateSpeciality.dart';
import '../Utils/BaseURL.dart' as baseURL;
import 'QuestionListPage.dart';
// import 'QuestionService.dart'; // No longer needed

class AskQuestionPage extends StatefulWidget {
  final String userId;
  const AskQuestionPage({super.key, required this.userId});

  @override
  State<AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  final TextEditingController messageCtrl = TextEditingController();

  AdvocateSpeciality? selectedSpeciality;
  PlatformFile? selectedFile; // Unified for web/mobile
  String? fileName;
  String? fileExtension;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Ask Question")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ---------------- QUESTION TEXT ----------------
            TextField(
              controller: messageCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Write your legal question...",
                hintStyle: const TextStyle(color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ---------------- SPECIALITY SELECTOR ----------------
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select Speciality",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.black),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: GridView.builder(
                itemCount: AdvocateSpeciality.values.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  final speciality = AdvocateSpeciality.values[index];
                  final isSelected = speciality == selectedSpeciality;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() => selectedSpeciality = speciality);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green
                            : Colors.white70,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.green),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(speciality.icon, color: Colors.black, size: 30),
                          const SizedBox(height: 10),
                          Text(
                            speciality.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// ---------------- ATTACHMENT ----------------
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text("Attach File"),
                ),
                const SizedBox(width: 10),
                if (fileName != null)
                  Expanded(
                    child: Text(
                      fileName!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            /// ---------------- SUBMIT ----------------
            ElevatedButton(
              onPressed: () async {

                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {

                      return AlertDialog (
                        title: Text("Submitting question...."),
                        content: Column(
                            mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 10),
                            Text('In progress....'),
                          ]
                        ),
                      );

                    }
                );

                try {

                  await submit();

                  if(context.mounted) {

                    Navigator.pop(context);

                  }

                } catch(e) {

                  if(context.mounted) {

                    Navigator.pop(context);

                  }

                }

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Submit Question"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: seeAllQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("See All Question"),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- PICK FILE ----------------

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
  }

  /// ---------------- SUBMIT ----------------
  Future<void> submit() async {
    if (selectedSpeciality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a speciality")),
      );
      return;
    }

    if (messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a message")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final uri = Uri.parse("${baseURL.Urls().baseURL}questions/ask"); // From your backend endpoint

    var request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer $token";

    request.fields["userId"] = widget.userId; // Assuming usersId is a typo or same as userId; adjust if needed
    request.fields["usersId"] = widget.userId; // If backend requires both, set accordingly
    request.fields["message"] = messageCtrl.text.trim();
    request.fields["questionType"] = selectedSpeciality!.apiValue;

    if (selectedFile != null) {
      final mimeTypeStr = getMimeType(fileExtension);
      MediaType? contentType = mimeTypeStr != null ? MediaType.parse(mimeTypeStr) : null;

      if (kIsWeb) {
        // Web: use bytes
        if (selectedFile!.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              "file",
              selectedFile!.bytes!,
              filename: selectedFile!.name, // Critical: sets originalFilename in backend
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
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Question submitted successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.body}")),
      );
    }
  }

  Future<void> seeAllQuestion() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const QuestionListPage()),
    );
  }
}