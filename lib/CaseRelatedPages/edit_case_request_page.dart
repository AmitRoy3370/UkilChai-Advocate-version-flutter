import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:advocatechaiadvocate/AdvocatePages/AdvocateDetailsModel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../AdvocatePages/AdvocateDetails.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './case_request.dart';
import './case_request_service.dart';
import '../Utils/AdvocateSpeciality.dart';
import 'CaseRequestAttachmentViewer.dart';
import '../PageTransition.dart';

class EditCaseRequestPage extends StatefulWidget {
  final CaseRequest caseRequest;

  const EditCaseRequestPage({super.key, required this.caseRequest});

  @override
  State<EditCaseRequestPage> createState() => _EditCaseRequestPageState();
}

class _EditCaseRequestPageState extends State<EditCaseRequestPage> {
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

  final service = CaseRequestService();
  final List<PageTransitionType> _animations = AnimatedRoute.getCompanySafeAnimations();
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    nameCtrl.text = widget.caseRequest.caseName;
    selectedType = widget.caseRequest.caseType;
    existingAttachments = (widget.caseRequest.attachmentId ?? [])
        .where((id) => id != null && id.isNotEmpty && id != "null" && id != "attachmentId")
        .cast<String>()
        .toList();

    if (widget.caseRequest.requestedAdvocateId != null) {
      requestedAdvocateId = widget.caseRequest.requestedAdvocateId;
    }

    getTheAdvocatesDetais();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
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
          final name = advocate.name ?? await getAdvocateName(advocate.userId);
          loadedNames.add(name);
        }

        if (mounted) {
          setState(() {
            advocates = loadedAdvocates;
            nameOfAdvocates = loadedNames;
            advocateLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
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

  Future<String> getAdvocateName(String? advocateId) async {
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
      withData: true,
    );

    if (result != null && mounted) {
      setState(() {
        newFiles.addAll(result.files);
      });
    }
  }

  void _viewAttachment(String attachmentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jwtToken = prefs.getString('jwt_token') ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseRequestAttachmentViewer(
          attachmentId: attachmentId,
          jwtToken: jwtToken,
        ),
      ),
    );
  }

  Future<void> deleteExistingAttachment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Remove Attachment",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to remove this attachment?",
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              "Remove",
              style: GoogleFonts.inter(),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        existingAttachments.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Attachment removed", style: GoogleFonts.inter()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> update() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final ok = await service.updateCaseRequest(
      caseRequestId: widget.caseRequest.id,
      caseName: nameCtrl.text.trim(),
      caseType: selectedType.apiValue,
      userId: widget.caseRequest.userId,
      existingFiles: existingAttachments,
      files: newFiles,
      requestedAdvocateId: requestedAdvocateId,
    );

    if (mounted) {
      setState(() => loading = false);
    }

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Case updated successfully", style: GoogleFonts.inter()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update case", style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getTypeColor(AdvocateSpeciality type) {
    switch (type) {
      case AdvocateSpeciality.CRIMINAL_LAWYER:
        return Colors.red;
      case AdvocateSpeciality.CIVIL_LAWYER:
        return Colors.blue;
      case AdvocateSpeciality.FAMILY_LAWYER:
        return Colors.orange;
      case AdvocateSpeciality.CORPORATE_LAWYER:
        return Colors.deepPurple;
      case AdvocateSpeciality.CYBER_CRIME_LAWYER:
        return Colors.cyan;
      case AdvocateSpeciality.PROPERTY_LAWYER:
        return Colors.green;
      case AdvocateSpeciality.INTELLECTUAL_PROPERTY_LAWYER:
        return Colors.indigo;
      case AdvocateSpeciality.TAX_LAWYER:
        return Colors.teal;
      case AdvocateSpeciality.LABOR_LAWYER:
        return Colors.brown;
      case AdvocateSpeciality.TRADE_LAWYER:
        return Colors.amber;
      case AdvocateSpeciality.BANKING_LAWYER:
        return Colors.lightBlue;
      case AdvocateSpeciality.INSURANCE_LAWYER:
        return Colors.pink;
      case AdvocateSpeciality.WOMEN_AND_CHILD_RIGHTS_LAWYER:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Edit Case Request",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF1A237E),
                Color(0xFF283593),
                Color(0xFF3949AB),
              ],
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getTypeColor(selectedType),
                            _getTypeColor(selectedType).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              selectedType.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Edit Case",
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Update your case details",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Case Description Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description, size: 18, color: const Color(0xFF1A237E)),
                              const SizedBox(width: 8),
                              Text(
                                "Case Description",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nameCtrl,
                            style: GoogleFonts.inter(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "Enter case description",
                              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1A237E)),
                              ),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                            validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Case Type Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category, size: 18, color: const Color(0xFF1A237E)),
                              const SizedBox(width: 8),
                              Text(
                                "Case Type",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<AdvocateSpeciality>(
                            value: selectedType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1A237E)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: AdvocateSpeciality.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(type.icon, size: 20, color: const Color(0xFF1A237E)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        type.label,
                                        style: GoogleFonts.inter(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedType = newValue;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Select Advocate Card
                    if (!advocateLoading && advocates.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, size: 18, color: const Color(0xFF1A237E)),
                                const SizedBox(width: 8),
                                Text(
                                  "Select Advocate",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: requestedAdvocateId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF1A237E)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: advocates.asMap().entries.map((e) {
                                return DropdownMenuItem(
                                  value: e.value.id,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                                        child: Text(
                                          nameOfAdvocates[e.key][0].toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1A237E),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          nameOfAdvocates[e.key],
                                          style: GoogleFonts.inter(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setState(() {
                                  requestedAdvocateId = v;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    if (advocateLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: 16),

                    // Existing Attachments Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_file, size: 18, color: const Color(0xFF1A237E)),
                              const SizedBox(width: 8),
                              Text(
                                "Existing Attachments",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (existingAttachments.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  "No existing attachments",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: existingAttachments.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final id = existingAttachments[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _viewAttachment(id),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A237E).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.insert_drive_file,
                                            color: Color(0xFF1A237E),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _viewAttachment(id),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Attachment ${index + 1}",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              Text(
                                                "Tap to view",
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: const Color(0xFF1A237E),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () => deleteExistingAttachment(id),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // New Files Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_circle, size: 18, color: const Color(0xFF1A237E)),
                              const SizedBox(width: 8),
                              Text(
                                "Add New Files",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: pickFiles,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("Add Files"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          if (newFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: newFiles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final file = newFiles[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.insert_drive_file,
                                          color: Colors.green,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          file.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            newFiles.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: update,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.update, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Update Case Request",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}