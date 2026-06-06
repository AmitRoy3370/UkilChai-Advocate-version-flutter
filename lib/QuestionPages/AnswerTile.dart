import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as baseURL;
import 'AnswerModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'answer_response.dart';

class AnswerTile extends StatelessWidget {
  final AnswerResponse answer;
  final VoidCallback? onRefresh;
  const AnswerTile({required this.answer, this.onRefresh, super.key});

  get advocateId async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final advocateId = preferences.getString("advocateId");
    return advocateId;
  }

  Future<String> getNameFromUser(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final url = "${baseURL.Urls().baseURL}user/search?userId=$userId";
    final response = await http.get(
      Uri.parse(url),
      headers: {"content-type": "application/json", "Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body["name"] ?? "";
    }
    return "";
  }

  Future<String> getNameFromAdvocate(String advocateId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final url = "${baseURL.Urls().baseURL}advocate/$advocateId";
    final response = await http.get(
      Uri.parse(url),
      headers: {"content-type": "application/json", "Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final userId = body["userId"];
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
      final url = "${baseURL.Urls().baseURL}answers/download?attachmentId=$attachmentId";
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download failed")),
        );
        return;
      }

      String fileName = "attachment";
      final disposition = response.headers['content-disposition'];
      if (disposition != null) {
        final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
        if (match != null) fileName = match.group(1)!;
      }

      final contentType = response.headers['content-type'] ?? "application/octet-stream";
      if (!fileName.contains(".")) fileName += _getExtensionFromContentType(contentType);

      if (kIsWeb) {
        final blob = html.Blob([response.bodyBytes], contentType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)..setAttribute("download", fileName)..click();
        html.Url.revokeObjectUrl(url);
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/$fileName";
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Attachment error: $e")),
      );
    }
  }

  Future<String> getAdvocateId() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString("advocateId") ?? '';
  }

  String? getMimeType(String? extension) {
    if (extension == null) return null;
    extension = extension.toLowerCase();
    switch (extension) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'pdf': return 'application/pdf';
      case 'mp4': return 'video/mp4';
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt': return 'text/plain';
      case 'json': return 'application/json';
      default: return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAttachment = answer.attachmentId != null && answer.attachmentId!.isNotEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.05),
              Colors.blue.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: FutureBuilder<String>(
          future: getAdvocateId(),
          builder: (context, snapshot) {
            final isOwnAnswer = snapshot.hasData && snapshot.data == answer.advocateId;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified, size: 14, color: Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        answer.advocateName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    if (isOwnAnswer)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, size: 18, color: Colors.grey[600]),
                            onPressed: () {
                              _showEditDialog(context);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
                            onPressed: () {
                              _showDeleteDialog(context);
                            },
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  answer.message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                if (hasAttachment) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => openAttachment(context, answer.attachmentId!),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            "View Attachment",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    String editedMessage = answer.message;
    PlatformFile? pickedFile;
    String? fileName;
    String? fileExtension;
    bool removeAttachment = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool hasExistingAttachment = answer.attachmentId != null && answer.attachmentId!.isNotEmpty;
            
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Edit Answer", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Message",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    controller: TextEditingController(text: answer.message),
                    keyboardType: TextInputType.multiline,
                    onChanged: (value) => editedMessage = value,
                    maxLines: 3,
                    style: GoogleFonts.inter(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Existing Attachment Section
                  if (hasExistingAttachment && !removeAttachment && pickedFile == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, size: 20, color: Colors.green.shade700),
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
                                  "File attached to this answer",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
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
                              setDialogState(() {
                                removeAttachment = true;
                                pickedFile = null;
                                fileName = null;
                              });
                            },
                            tooltip: "Remove attachment",
                          ),
                        ],
                      ),
                    ),
                  
                  // New Attachment Section
                  if (pickedFile != null && fileName != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file, size: 20, color: Colors.blue.shade700),
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
                                    fontSize: 13,
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
                              setDialogState(() {
                                pickedFile = null;
                                fileName = null;
                                fileExtension = null;
                              });
                            },
                            tooltip: "Remove selected file",
                          ),
                        ],
                      ),
                    ),
                  
                  // Add/Change Attachment Button
                  if ((!hasExistingAttachment || removeAttachment) && pickedFile == null)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: false,
                            withData: true,
                            type: FileType.any,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            pickedFile = result.files.first;
                            fileName = pickedFile!.name;
                            fileExtension = pickedFile!.extension;
                            setDialogState(() {});
                          }
                        },
                        icon: const Icon(Icons.cloud_upload, size: 18),
                        label: const Text("Choose Attachment"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  
                  // Change Attachment Button (when existing attachment exists and not removed)
                  if (hasExistingAttachment && !removeAttachment && pickedFile == null)
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: false,
                            withData: true,
                            type: FileType.any,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            pickedFile = result.files.first;
                            fileName = pickedFile!.name;
                            fileExtension = pickedFile!.extension;
                            setDialogState(() {});
                          }
                        },
                        icon: const Icon(Icons.change_circle, size: 18),
                        label: Text("Change Attachment", style: GoogleFonts.inter()),
                        style: TextButton.styleFrom(foregroundColor: Colors.green),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text("Updating answer...", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Colors.green),
                              const SizedBox(height: 10),
                              Text("Please wait...", style: GoogleFonts.inter()),
                            ],
                          ),
                        );
                      },
                    );

                    try {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('jwt_token') ?? '';
                      final userId = prefs.getString('userId') ?? '';

                      var request = http.MultipartRequest(
                        'PUT',
                        Uri.parse("${baseURL.Urls().baseURL}answers/update/${answer.id}"),
                      );

                      request.headers['Authorization'] = 'Bearer $token';
                      request.fields['advocateId'] = answer.advocateId;
                      request.fields['message'] = editedMessage;
                      request.fields['questionId'] = answer.questionId;
                      request.fields['userId'] = userId;

                      // Handle attachment logic
                      if (removeAttachment) {
                        // User wants to remove the attachment
                        request.fields['attachmentId'] = "";
                      } else if (pickedFile != null) {
                        // User selected a new file, don't send attachmentId
                        // The backend will create a new attachment
                      } else if (hasExistingAttachment && !removeAttachment) {
                        // Keep existing attachment
                        request.fields['attachmentId'] = answer.attachmentId!;
                      } else {
                        // No attachment
                        request.fields['attachmentId'] = "";
                      }

                      if (pickedFile != null) {
                        final mimeTypeStr = getMimeType(fileExtension);
                        http.MediaType? contentType = mimeTypeStr != null
                            ? http.MediaType.parse(mimeTypeStr)
                            : null;

                        List<int> fileBytesToSend;
                        if (kIsWeb) {
                          fileBytesToSend = pickedFile!.bytes!;
                        } else {
                          if (pickedFile!.path != null) {
                            final file = File(pickedFile!.path!);
                            fileBytesToSend = await file.readAsBytes();
                          } else if (pickedFile!.bytes != null) {
                            fileBytesToSend = pickedFile!.bytes!;
                          } else {
                            fileBytesToSend = [];
                          }
                        }

                        request.files.add(
                          http.MultipartFile.fromBytes(
                            "file",
                            fileBytesToSend,
                            filename: pickedFile!.name,
                            contentType: contentType,
                          ),
                        );
                      }

                      var streamedResponse = await request.send();
                      var response = await http.Response.fromStream(streamedResponse);

                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) Navigator.pop(dialogContext);

                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Answer updated successfully", style: GoogleFonts.inter()),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        onRefresh?.call();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to update: ${response.body}", style: GoogleFonts.inter()),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e", style: GoogleFonts.inter()),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Delete Answer", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: Text(
            "Are you sure you want to delete this answer?",
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.red),
                          const SizedBox(height: 10),
                          Text("Deleting...", style: GoogleFonts.inter()),
                        ],
                      ),
                    );
                  },
                );

                SharedPreferences prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('jwt_token') ?? '';
                final userId = prefs.getString('userId') ?? '';

                final deleteResponse = await http.delete(
                  Uri.parse("${baseURL.Urls().baseURL}answers/delete/${answer.id}?userId=$userId"),
                  headers: {
                    "content-type": "application/json",
                    "Authorization": "Bearer $token",
                  },
                );

                if (context.mounted) Navigator.pop(context);
                if (context.mounted) Navigator.pop(dialogContext);

                if (deleteResponse.statusCode == 200 || deleteResponse.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Answer deleted successfully", style: GoogleFonts.inter()),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  onRefresh?.call();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Answer not deleted", style: GoogleFonts.inter()),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}