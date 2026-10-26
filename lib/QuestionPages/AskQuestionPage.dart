import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Utils/AdvocateSpeciality.dart';
import '../Utils/BaseURL.dart' as baseURL;
import 'QuestionListPage.dart';
import '../PageTransition.dart';

class AskQuestionPage extends StatefulWidget {
  final String userId;
  const AskQuestionPage({super.key, required this.userId});

  @override
  State<AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  final TextEditingController messageCtrl = TextEditingController();

  AdvocateSpeciality? selectedSpeciality;
  PlatformFile? selectedFile;
  String? fileName;
  String? fileExtension;

  final List<PageTransitionType> _smoothAnimations = AnimatedRoute.getCompanySafeAnimations();

  PageTransitionType _getRandomAnimation() {
    final random = Random().nextInt(_smoothAnimations.length);
    return _smoothAnimations[random];
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Ask Question",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E), // Deep Navy
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E), // Deep Navy
                Color(0xFF283593), // Indigo
                Color(0xFF3949AB), // Lighter Indigo
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A237E), // Deep Navy
                    Color(0xFF283593), // Indigo
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
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Have a Legal Question?",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Get answers from expert advocates",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Question Input Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, size: 18, color: Color(0xFF1A237E)),
                      const SizedBox(width: 8),
                      Text(
                        "Your Question",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 5,
                    style: GoogleFonts.inter(color: Colors.grey[800]),
                    decoration: InputDecoration(
                      hintText: "Write your legal question...",
                      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ========== 🔥 স্পেশালিটি সিলেকশন (২টি সারিতে স্ক্রোলযোগ্য) ==========
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.category, size: 18, color: Color(0xFF1A237E)),
                      const SizedBox(width: 8),
                      Text(
                        "Select Speciality",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 🔥 ২টি সারিতে স্ক্রোলযোগ্য স্পেশালিটি
                  _buildSpecialitySelector(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Attachment Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 18, color: Color(0xFF1A237E)),
                      const SizedBox(width: 8),
                      Text(
                        "Attachment (Optional)",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickFile,
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text("Choose File"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (fileName != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    fileName!,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              "Asking question...",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: Color(0xFF1A237E)),
                                const SizedBox(height: 10),
                                Text(
                                  "Please wait while we process your question...",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );

                      await submit();

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(
                      "Submit Question",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E), // Deep Navy
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => seeAllQuestion(),
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: Text(
                      "See All Questions",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A237E),
                      side: const BorderSide(color: Color(0xFF1A237E)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ========== 🔥 স্পেশালিটি সিলেক্টর (২টি সারিতে স্ক্রোলযোগ্য) ==========
  Widget _buildSpecialitySelector() {
    final allTypes = AdvocateSpeciality.values;
    final totalTypes = allTypes.length;
    
    // প্রথম অর্ধেক এবং দ্বিতীয় অর্ধেকে ভাগ করা
    final int midPoint = (totalTypes / 2).ceil();
    final List<AdvocateSpeciality> firstHalf = allTypes.sublist(0, midPoint);
    final List<AdvocateSpeciality> secondHalf = allTypes.sublist(midPoint);

    return Column(
      children: [
        // 🔥 প্রথম সারি
        _buildSpecialityRow(firstHalf),
        const SizedBox(height: 10), // ২টি সারির মধ্যে গ্যাপ
        // 🔥 দ্বিতীয় সারি
        _buildSpecialityRow(secondHalf),
      ],
    );
  }

  // ========== 🔥 স্পেশালিটির সারি (স্ক্রোলযোগ্য) ==========
  Widget _buildSpecialityRow(List<AdvocateSpeciality> items) {
    return SizedBox(
      height: 85, // সারির উচ্চতা
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // বাম-ডানে স্ক্রোল
        physics: const BouncingScrollPhysics(), // স্মুথ স্ক্রোল
        itemCount: items.length,
        itemBuilder: (context, index) {
          final type = items[index];
          final isSelected = selectedSpeciality == type;
          
          return Container(
            width: 95, // প্রতিটি আইটেমের প্রস্থ
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildTypeChip(type, isSelected),
          );
        },
      ),
    );
  }

  // ========== টাইপ চিপ ==========
  Widget _buildTypeChip(AdvocateSpeciality type, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedSpeciality = null; // ডিসিলেক্ট
          } else {
            selectedSpeciality = type; // সিলেক্ট
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A237E), // Deep Navy
                    Color(0xFF283593), // Indigo
                  ],
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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

  /// ---------------- PICK FILE ----------------
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
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
        SnackBar(
          content: Text(
            "Please select a speciality",
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter a message",
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final uri = Uri.parse("${baseURL.Urls().baseURL}questions/ask");

    var request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer $token";

    request.fields["userId"] = widget.userId;
    request.fields["usersId"] = widget.userId;
    request.fields["message"] = messageCtrl.text.trim();
    request.fields["questionType"] = selectedSpeciality!.apiValue;

    if (selectedFile != null) {
      final mimeTypeStr = getMimeType(fileExtension);
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
              "file",
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Question submitted successfully",
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed: ${response.body}",
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> seeAllQuestion() async {
    await NavigationHelper.push(
      context,
      QuestionListPage(),
      transitionType: _getRandomAnimation(),
      duration: const Duration(milliseconds: 400),
    );
  }
}