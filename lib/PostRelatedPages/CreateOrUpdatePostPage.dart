import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:advocatechaiadvocate/PostRelatedPages/post_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../PostRelatedPages/PostAttachmentViewer.dart';
import '../Utils/AdvocateSpeciality.dart';
import '../Utils/BaseURL.dart' as baseURL;
import 'AdvocatePost.dart';

class CreateOrUpdatePostPage extends StatefulWidget {
  final PostResponse? post;
  final Function? refresh;
  const CreateOrUpdatePostPage({super.key, this.post, this.refresh});

  @override
  State<CreateOrUpdatePostPage> createState() => _CreateOrUpdatePostPageState();
}

class _CreateOrUpdatePostPageState extends State<CreateOrUpdatePostPage> {
  final TextEditingController contentController = TextEditingController();
  bool get isUpdate => widget.post != null;

  AdvocateSpeciality selectedType = AdvocateSpeciality.CRIMINAL_LAWYER;

  PlatformFile? selectedFile;
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
      selectedType = AdvocateSpecialityExt.fromApi(
        widget.post!.postType.apiValue,
      );
      if (hasExistingAttachment) {
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
      allowMultiple: false,
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
        if (isUpdate) {
          removeOldAttachment = false;
        }
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

  // ALWAYS send attachmentId for update requests
  if (isUpdate) {
    String? attachmentIdValue;
    
    if (selectedFile != null) {
      // When uploading new file, send the existing attachmentId if it exists, otherwise send empty string
      attachmentIdValue = hasExistingAttachment ? widget.post!.attachmentId! : "";
    } else if (removeOldAttachment) {
      // Removing attachment
      //attachmentIdValue = "";
    } else if (hasExistingAttachment) {
      // Keeping existing attachment
      attachmentIdValue = widget.post!.attachmentId!;
    } else {
      // No attachment
      //attachmentIdValue = "";
    }
    
    if(attachmentIdValue != null) {

        request.fields["attachmentId"] = attachmentIdValue!;
        print("Sending attachmentId: $attachmentIdValue");

    }

  }

  // Add file if selected
  if (selectedFile != null) {
    final mimeTypeStr = getMimeType(fileExtension);
    MediaType? contentType = mimeTypeStr != null
        ? MediaType.parse(mimeTypeStr)
        : null;

    List<int> fileBytesToSend;
    if (kIsWeb) {
      fileBytesToSend = selectedFile!.bytes!;
    } else {
      if (selectedFile!.path != null) {
        final file = File(selectedFile!.path!);
        fileBytesToSend = await file.readAsBytes();
      } else if (selectedFile!.bytes != null) {
        fileBytesToSend = selectedFile!.bytes!;
      } else {
        fileBytesToSend = [];
      }
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        fileBytesToSend,
        filename: selectedFile!.name,
        contentType: contentType,
      ),
    );
    print("Adding file: ${selectedFile!.name}, size: ${selectedFile!.size}");
  }

  print("isUpdate: $isUpdate");
  print("Has selectedFile: ${selectedFile != null}");
  print("Fields: ${request.fields}");
  print("Has file in request: ${request.files.isNotEmpty}");

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

  print("Status: ${response.statusCode}");
  print("Body: $responseBody");

  if (response.statusCode == 200 || response.statusCode == 201) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isUpdate ? "Post updated successfully!" : "Post created successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed: $responseBody"), 
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  void showSpecialityDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                "Select Speciality",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AdvocateSpeciality.values.map((e) {
                    return RadioListTile<AdvocateSpeciality>(
                      title: Text(e.label, style: GoogleFonts.inter()),
                      value: e,
                      groupValue: selectedType,
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val != null) {
                            selectedType = val;
                          }
                        });
                      },
                      activeColor: Colors.green,
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
                  child: Text("Done", style: GoogleFonts.inter(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Check if attachment exists
  bool get hasExistingAttachment {
    if (!isUpdate) return false;
    final attachmentId = widget.post!.attachmentId;
    return attachmentId != null &&
        attachmentId.isNotEmpty &&
        attachmentId != "null" &&
        attachmentId != "attachmentId";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isUpdate ? "Update Post" : "Create New Post",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Content Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: contentController,
                maxLines: 8,
                style: GoogleFonts.inter(fontSize: 16, height: 1.5),
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Speciality Selection
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade600],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_offer, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Legal Speciality",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedType.label,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: showSpecialityDialog,
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Change"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Attachment Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.blue.shade600],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.attach_file, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Attachment (Optional)",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Show existing attachment
                    if (hasExistingAttachment && !removeOldAttachment && selectedFile == null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Current Attachment",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                  Text(
                                    "File attached to this post",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                              onPressed: () {
                                setState(() {
                                  removeOldAttachment = true;
                                  selectedFile = null;
                                  fileName = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    // Show selected new file
                    if (selectedFile != null && fileName != null && fileName!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "New Attachment",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                  Text(
                                    fileName!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                              onPressed: () {
                                setState(() {
                                  selectedFile = null;
                                  fileName = null;
                                  fileExtension = null;
                                  fileBytes = null;
                                  fileSelected = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    // Add file button
                    if (selectedFile == null && 
                        (!hasExistingAttachment || removeOldAttachment || !isUpdate))
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: pickFiles,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text("Choose File"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ),
                    
                    // Show info text
                    if (selectedFile == null && 
                        isUpdate && 
                        !hasExistingAttachment && 
                        !removeOldAttachment)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            "No attachment currently attached to this post",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (contentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter post content"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.green),
                            const SizedBox(height: 16),
                            Text(
                              isUpdate ? "Updating post..." : "Creating post...",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  await submitPost();
                  widget.refresh?.call();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isUpdate ? "Update Post" : "Publish Post",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}