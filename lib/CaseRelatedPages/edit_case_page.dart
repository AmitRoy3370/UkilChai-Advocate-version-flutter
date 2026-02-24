import 'dart:convert';
import 'dart:io';
import 'package:advocatechaiadvocate/AdvocatePages/AdvocateDetailsModel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../AdvocatePages/AdvocateDetails.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './case_request.dart';
import './case_request_service.dart';
import '../Utils/AdvocateSpeciality.dart';
import 'AttachmentViewer.dart';
import 'CaseRequestAttachmentViewer.dart';
import 'case_model.dart';
import 'case_service.dart';

class EditCasePage extends StatefulWidget {
  final CaseModel acceptedCase;
  final String? token;

  const EditCasePage({super.key, required this.acceptedCase, required this.token});

  @override
  State<EditCasePage> createState() => _EditCasePageState();
}

class _EditCasePageState extends State<EditCasePage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final List<PlatformFile> files = [];
  late List<AdvocateDetailsModel> advocates = [];
  late List<String> nameOfAdvocates = [];
  bool loading = false;
  bool advocateLoading = true;
  late AdvocateSpeciality selectedType;
  late List<String> existingAttachments;
  final List<PlatformFile> newFiles = [];
  var requestedAdvocateId;

  late final service = CaseService(widget.token!);

  @override
  void initState() {
    super.initState();
    nameCtrl.text = widget.acceptedCase.caseName;
    selectedType = AdvocateSpecialityExt.fromApi(widget.acceptedCase.caseType);
    existingAttachments = List.from(widget.acceptedCase.attachmentsId);

    if (widget.acceptedCase.advocateId.isNotEmpty) {
      setState(() {
        requestedAdvocateId = widget.acceptedCase.advocateId;
      });
    }

    getTheAdvocatesDetais();
  }

  Future<void> getTheAdvocatesDetais() async {
    try {
      final uri = Uri.parse("${BASE_URL.Urls().baseURL}advocate/all");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.get(
        uri,
        headers: {
          "content-type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List body = jsonDecode(response.body);

        List<AdvocateDetailsModel> loadedAdvocates = [];
        List<String> loadedNames = [];

        for (var item in body) {
          final advocate = AdvocateDetailsModel.fromJson(item);
          loadedAdvocates.add(advocate);

          // 🔥 fetch advocate name via userId
          final name = await getNameFromUser(advocate.userId);
          loadedNames.add(name);
        }

        if (mounted) {
          setState(() {
            advocates = loadedAdvocates;
            nameOfAdvocates = loadedNames;
            advocateLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          advocateLoading = false;
        });
      }
      debugPrint("Error loading advocates: $e");
    }
  }

  Widget requestedAdvocateWidget() {
    if (advocateLoading || requestedAdvocateId == null) {
      return const SizedBox.shrink();
    }

    final index = advocates.indexWhere((a) => a.id == requestedAdvocateId);

    if (index == -1) return const SizedBox.shrink();

    return Text(
      "Requested Advocate: ${nameOfAdvocates[index]}",
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  // Get the advocate name
  Future<String> getAdvocateName(String advocateId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final url = "${BASE_URL.Urls().baseURL}advocate/$advocateId";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final userId = body["userId"];

      return getNameFromUser(userId);
    } else {
      return "";
    }
  }

  // ---------------- GET USER NAME ----------------
  Future<String> getNameFromUser(String? userId) async {
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

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true, // 🔥 REQUIRED for Web
    );

    if (result != null) {
      setState(() {
        newFiles.addAll(result.files);
      });
    }
  }

  Future<void> deleteExistingAttachment(String id) async {
    final ok = await service.deleteAttachment(id);
    if (ok && mounted) {
      setState(() {
        existingAttachments.remove(id);
      });
    }
  }

  Future<void> update() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String userId = prefs.getString('userId') ?? '';

    final ok = await service.updateCase(
      caseId: widget.acceptedCase.id,
      caseName: nameCtrl.text.trim(),
      caseType: selectedType.apiValue,
      usersId: userId,
      existingFiles: existingAttachments, // ✅ String list
      newFiles: newFiles, // ✅ PlatformFile list
      advocateId: requestedAdvocateId,
      userId: widget.acceptedCase.userId,

    );

    setState(() => loading = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Case updated successfully")),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Case")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Case Name"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 12),

                    if (!advocateLoading)
                      DropdownButtonFormField<String>(
                        value: requestedAdvocateId,
                        decoration: const InputDecoration(
                          labelText: "Select Advocate",
                        ),
                        items: advocates.asMap().entries.map((e) {
                          return DropdownMenuItem(
                            value: e.value.id,
                            child: Text(nameOfAdvocates[e.key]),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            requestedAdvocateId = v;
                          });
                        },
                      ),

                    const SizedBox(height: 20),

                    FutureBuilder<String>(
                      future: getAdvocateName(requestedAdvocateId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text("Loading advocate...");
                        }
                        if (!snapshot.hasData || snapshot.hasError) {
                          return const SizedBox.shrink();
                        }
                        return Text("Requested Advocate: ${snapshot.data}");
                      },
                    ),
                    const Divider(),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Advocate",
                      ),
                      items: advocates.asMap().entries.map((e) {
                        return DropdownMenuItem(
                          value: e.value.id,
                          child: Text(nameOfAdvocates[e.key]),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          requestedAdvocateId = v;
                        });
                      },
                    ),

                    /// -------- EXISTING FILES --------
                    const Text(
                      "Existing Attachments",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    if (existingAttachments.isEmpty)
                      const Text("No existing files"),

                    ...existingAttachments.map(
                      (id) => ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(id),
                        onTap: () async {
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String jwtToken = prefs.getString('jwt_token') ?? '';

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CaseAttachmentView(
                                attachmentId: id,
                                jwtToken: jwtToken,
                              ),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            deleteExistingAttachment(id);

                            setState(() {

                              existingAttachments.remove(id);

                            });

                          },
                        ),
                      ),
                    ),

                    const Divider(height: 32),

                    /// -------- NEW FILES --------
                    const Text(
                      "New Files",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Add Files"),
                      onPressed: pickFiles,
                    ),

                    ...newFiles.asMap().entries.map(
                      (e) => ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(e.value.name),

                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              newFiles.removeAt(e.key);
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: update,
                      child: const Text("Update Case"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
