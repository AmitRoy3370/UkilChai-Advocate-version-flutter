import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this import for MediaType
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../PostRelatedPages/PostAttachmentViewer.dart';

import '../Utils/AdvocateSpeciality.dart';
import '../Utils/BaseURL.dart' as baseURL;
import 'AdvocatePost.dart';
// import 'PostAttachmentViewer.dart'; // Uncomment if needed

class CreateOrUpdatePostPage extends StatefulWidget {
  final AdvocatePost? post;
  const CreateOrUpdatePostPage({super.key, this.post});

  @override
  State<CreateOrUpdatePostPage> createState() => _CreateOrUpdatePostPageState();
}

class _CreateOrUpdatePostPageState extends State<CreateOrUpdatePostPage> {
  final TextEditingController contentController = TextEditingController();
  bool get isUpdate => widget.post != null;

  AdvocateSpeciality selectedType = AdvocateSpeciality.CRIMINAL_LAWYER;

  PlatformFile? selectedFile; // Unified for single file
  String? fileName;
  String? fileExtension;
  Uint8List? fileBytes;
  bool fileSelected = false;
  bool removeOldAttachment = false;

  @override
  void initState() {
    super.initState();
    if (isUpdate) {
      contentController.text = widget.post!.postContent;
      selectedType = AdvocateSpecialityExt.fromApi(widget.post!.postType);
      if (widget.post!.attachmentId != null &&
          widget.post!.attachmentId!.isNotEmpty) {
        fileName = "Existing Attachment";
      }
    }
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
        fileSelected = true;
        if (isUpdate) removeOldAttachment = false; // New file will replace
      });
    }
  }

  Future<void> submitPost() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";
    final userId = prefs.getString("userId") ?? "";
    final advocateId = prefs.getString("advocateId") ?? "";

    final uri = isUpdate
        ? Uri.parse(
            "${baseURL.Urls().baseURL}advocate/posts/update/${widget.post!.id}/$userId",
          )
        : Uri.parse("${baseURL.Urls().baseURL}advocate/posts/upload/$userId");

    var request = http.MultipartRequest(isUpdate ? "PUT" : "POST", uri);
    request.headers["Authorization"] = "Bearer $token";

    request.fields["advocateId"] = advocateId;
    request.fields["postContent"] = contentController.text.trim();
    request.fields["postType"] = selectedType.apiValue;

    if (isUpdate) {
      if (removeOldAttachment) {
        request.fields["attachmentId"] = "";
      } else {
        request.fields["attachmentId"] = widget.post!.attachmentId ?? "";
      }
    }

    if (selectedFile != null) {
      final mimeTypeStr = getMimeType(fileExtension);
      print("mimetype of the file is :- $mimeTypeStr");

      MediaType? contentType = mimeTypeStr != null
          ? MediaType.parse(mimeTypeStr)
          : null;

      if (kIsWeb) {
        if (selectedFile!.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              "file",
              selectedFile!.bytes!,
              filename: selectedFile!.name,
              contentType: contentType,
            ),
          );
        }
      } else {
        if (selectedFile!.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              selectedFile!.path!,
              filename: selectedFile!.name,
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

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context);
    } else {
      final body = await response.stream.bytesToString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body)));
    }
  }

  void showSpecialityDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Specialities"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AdvocateSpeciality.values.map((e) {
                    return CheckboxListTile(
                      title: Text(e.label),
                      value: selectedType.apiValue == e.apiValue,
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val!) {
                            selectedType = e;
                          } else {
                            selectedType = AdvocateSpeciality.CRIMINAL_LAWYER;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isUpdate ? "Update Post" : "Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Post Content",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: showSpecialityDialog,
              child: const Text("Select Specialist"),
            ),
            const SizedBox(height: 16),
            Text("Post speciality :- ${selectedType.label}"),
            const SizedBox(height: 20),
            // -------- ATTACHMENT SECTION --------
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Attachment",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (widget.post != null && widget.post!.attachmentId != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.post!.attachmentId ?? "",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () async {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  final token =
                                      prefs.getString('jwt_token') ?? '';

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PostAttachmentView(
                                        attachmentId:
                                            widget.post!.attachmentId!,
                                        jwtToken: token,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              selectedFile = null;
                              fileName = null;
                              fileExtension = null;
                              fileBytes = null;
                              fileSelected = false;
                              if (isUpdate) removeOldAttachment = true;
                            });
                          },
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: pickFiles,
                    icon: const Icon(Icons.attach_file),
                    label: const Text("Attach File"),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitPost,
              child: Text(isUpdate ? "Update" : "Post"),
            ),
          ],
        ),
      ),
    );
  }
}
