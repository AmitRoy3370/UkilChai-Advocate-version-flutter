import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../Utils/AdvocateSpeciality.dart';
import 'QuestionListPage.dart';
import 'QuestionService.dart';

class AskQuestionPage extends StatefulWidget {
  final String userId;
  const AskQuestionPage({super.key, required this.userId});

  @override
  State<AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  final TextEditingController messageCtrl = TextEditingController();

  AdvocateSpeciality? selectedSpeciality;
  File? attachment, mobileFile;
  String? fileName;
  Uint8List? webFileBytes;

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
              onPressed: submit,
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
      withData: kIsWeb, // IMPORTANT
    );

    if (result == null) return;

    final file = result.files.first;

    setState(() {
      fileName = file.name;

      if (kIsWeb) {
        webFileBytes = file.bytes; // WEB
      } else {
        mobileFile = File(file.path!); // MOBILE
      }
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

    await QuestionService.askQuestion(
      userId: widget.userId,
      message: messageCtrl.text,
      questionType: selectedSpeciality!.apiValue,
      file: mobileFile,
      webFileBytes: webFileBytes,
      fileName: fileName,
    );


    Navigator.pop(context);
  }

  Future<void> seeAllQuestion() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const QuestionListPage()),
    );
  }
}
