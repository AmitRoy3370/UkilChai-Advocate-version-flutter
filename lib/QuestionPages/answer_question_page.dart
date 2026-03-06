import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class AnswerQuestionPage extends StatefulWidget {
  final String? questionId;
  final VoidCallback? onAnswerSubmitted;

  const AnswerQuestionPage({
    super.key,
    this.questionId,
    this.onAnswerSubmitted,
  });

  @override
  State<StatefulWidget> createState() {
    return _AnswerQuestionPageState();
  }
}

class _AnswerQuestionPageState extends State<AnswerQuestionPage> {
  TextEditingController messageCtrl = TextEditingController();
  PlatformFile? selectedFile; // Unified for single file
  String? fileName;
  String? fileExtension;
  Uint8List? fileBytes;

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

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple:
          false, // Changed to false since backend expects single "file"
      withData: true,
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = result.files.first;
        fileName = selectedFile!.name;
        fileExtension = selectedFile!.extension;
        fileBytes = selectedFile!.bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text("Attach File"),
            ),
            if (fileName != null)
              Text(
                fileName!,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
                controller: messageCtrl,
                decoration: InputDecoration(
                  hintText: "Write your answer...",
                  hintStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Answering Question"),
                      content: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          Text('In progress....'),
                        ],
                      ),
                    );
                  },
                );

                final message = messageCtrl.text;

                SharedPreferences prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('jwt_token') ?? '';
                final userId = prefs.getString('userId') ?? '';
                final advocateId = prefs.getString('advocateId') ?? '';

                Uri uri = Uri.parse("${BASE_URL.Urls().baseURL}answers/add");

                var answerResponse = http.MultipartRequest("POST", uri);

                answerResponse.fields["advocateId"] = advocateId;
                answerResponse.fields["userId"] = userId;
                answerResponse.fields["message"] = message;

                answerResponse.fields["questionId"] = widget.questionId!;

                if (selectedFile != null) {
                  final mimeTypeStr = getMimeType(fileExtension);
                  http.MediaType? contentType = mimeTypeStr != null
                      ? http.MediaType.parse(mimeTypeStr)
                      : null;

                  if (kIsWeb) {
                    // Web: use bytes
                    if (selectedFile!.bytes != null) {
                      answerResponse.files.add(
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
                      answerResponse.files.add(
                        await http.MultipartFile.fromPath(
                          "file",
                          selectedFile!.path!,
                          filename: selectedFile!.name, // Critical
                          contentType: contentType,
                        ),
                      );
                    } else if (selectedFile!.bytes != null) {
                      answerResponse.files.add(
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

                answerResponse.headers["Authorization"] = "Bearer $token";

                final response = await answerResponse.send();

                if (response.statusCode == 200 || response.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Answer sent successfully")),
                  );

                  setState(() {
                    selectedFile = null;
                    fileName = null;
                    fileExtension = null;
                    fileBytes = null;
                  });

                  messageCtrl.clear();

                  widget.onAnswerSubmitted?.call();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  final body = await response.stream.bytesToString();

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(body)));

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }

                setState(() {});
              },
              child: Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}
