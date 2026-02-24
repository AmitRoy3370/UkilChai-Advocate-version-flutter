import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
  final VoidCallback? onRefresh;
  const AnswerTile({required this.answer, this.onRefresh, super.key});

  get advocateId async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    final advocateId = preferences.getString("advocateId");

    return advocateId;
  }

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

  Future<String> getAdvocateId() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString("advocateId") ?? '';
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

  @override
  Widget build(BuildContext context) {
    String? fileName;
    String? fileExtension;
    Uint8List? fileBytes;

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
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Text("Advocate: N/A");
              } else {
                return Text(
                  "Advocate: ${snapshot.data}",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
            },
          ),

          FutureBuilder<String>(
            future: getAdvocateId(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Advocate: loading...");
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Text("Advocate: N/A");
              } else {
                final advocateId = snapshot.data!;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      answer.message,
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                    ),
                    if (answer.advocateId == advocateId)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text(''),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) {
                              String editedMessage = answer.message;
                              PlatformFile? pickedFile;
                              return AlertDialog(
                                title: const Text('Edit Answer'),
                                content: StatefulBuilder(
                                  builder: (context, setDialogState) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          decoration: const InputDecoration(
                                            labelText: 'Message',
                                          ),
                                          controller: TextEditingController(
                                            text: answer.message,
                                          ),
                                          keyboardType: TextInputType.multiline,
                                          onChanged: (value) =>
                                          editedMessage = value,
                                          maxLines: null,
                                        ),
                                        const SizedBox(height: 10),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final result = await FilePicker
                                                .platform
                                                .pickFiles(
                                              allowMultiple:
                                              false, // Changed to false since backend expects single "file"
                                              withData: true,
                                              type: FileType.any,
                                            );

                                            if (result != null &&
                                                result.files.isNotEmpty) {
                                              pickedFile = result.files.first;
                                              fileName = pickedFile!.name;
                                              fileExtension =
                                                  pickedFile!.extension;
                                              fileBytes = pickedFile!.bytes;

                                              setDialogState(() {

                                              });
                                            }
                                          },
                                          child: const Text(
                                            'Pick New Attachment',
                                          ),
                                        ),
                                        if (pickedFile != null)
                                          Text('Selected: ${pickedFile?.name}'),
                                        if (answer.attachmentId != null &&
                                            pickedFile == null)
                                          const Text(
                                            'Keeping existing attachment',
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                        final token =
                                            prefs.getString('jwt_token') ?? '';
                                        final userId =
                                            prefs.getString('userId') ?? '';

                                        var request = http.MultipartRequest(
                                          'PUT',
                                          Uri.parse(
                                            "${baseURL.Urls().baseURL}answers/update/${answer.id}",
                                          ),
                                        );

                                        request.headers['Authorization'] =
                                        'Bearer $token';

                                        request.fields['advocateId'] =
                                            answer.advocateId;
                                        request.fields['message'] =
                                            editedMessage;
                                        request.fields['questionId'] =
                                            answer.questionId;
                                        request.fields['userId'] = userId;

                                        if (answer.attachmentId != null &&
                                            pickedFile == null) {
                                          request.fields['attachmentId'] =
                                          answer.attachmentId!;
                                        }

                                        if (pickedFile != null) {
                                          final mimeTypeStr = getMimeType(
                                            fileExtension,
                                          );
                                          http.MediaType? contentType =
                                          mimeTypeStr != null
                                              ? http.MediaType.parse(
                                            mimeTypeStr,
                                          )
                                              : null;

                                          if (kIsWeb) {
                                            // Web: use bytes
                                            if (pickedFile!.bytes != null) {
                                              request.files.add(
                                                http.MultipartFile.fromBytes(
                                                  "file",
                                                  pickedFile!.bytes!,
                                                  filename: pickedFile!
                                                      .name, // Critical: sets originalFilename in backend
                                                  contentType:
                                                  contentType, // Sets proper MIME
                                                ),
                                              );
                                            }
                                          } else {
                                            // Mobile: prefer path, fallback to bytes
                                            if (pickedFile!.path != null) {
                                              request.files.add(
                                                await http
                                                    .MultipartFile.fromPath(
                                                  "file",
                                                  pickedFile!.path!,
                                                  filename: pickedFile!
                                                      .name, // Critical
                                                  contentType: contentType,
                                                ),
                                              );
                                            } else if (pickedFile!.bytes !=
                                                null) {
                                              request.files.add(
                                                http.MultipartFile.fromBytes(
                                                  "file",
                                                  pickedFile!.bytes!,
                                                  filename: pickedFile!.name,
                                                  contentType: contentType,
                                                ),
                                              );
                                            }
                                          }
                                        }

                                        var streamedResponse = await request
                                            .send();
                                        var response =
                                        await http.Response.fromStream(
                                          streamedResponse,
                                        );

                                        if (response.statusCode == 200) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Answer updated successfully',
                                              ),
                                            ),
                                          );
                                          Navigator.pop(dialogContext);
                                          onRefresh?.call();
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to update: ${response.statusCode}',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    },
                                    child: const Text('Update'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    if (answer.advocateId == advocateId)
                      ElevatedButton(
                        onPressed: () async {
                          SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                          final token = prefs.getString('jwt_token') ?? '';
                          final userId = prefs.getString('userId') ?? '';

                          final deleteResponse = await http.delete(
                            Uri.parse(
                              "${baseURL.Urls().baseURL}answers/delete/${answer.id}?userId=$userId",
                            ),
                            headers: {
                              "content-type": "application/json",
                              "Authorization": "Bearer $token",
                            },
                          );

                          if (deleteResponse.statusCode == 200 ||
                              deleteResponse.statusCode == 201) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Answer deleted successfully"),
                              ),
                            );

                            onRefresh?.call();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Answer not deleted"),
                              ),
                            );
                          }
                        },
                        child: Icon(Icons.delete),
                      ),
                  ],
                );
              }
            },
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