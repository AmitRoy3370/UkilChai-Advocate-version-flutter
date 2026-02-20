import 'package:flutter/material.dart';
import 'AppealCaseModel.dart';
import 'case_appeal_service.dart';

class AppealCasePage extends StatefulWidget {
  final String token;
  final String caseId;
  final String userId;

  const AppealCasePage({
    super.key,
    required this.token,
    required this.caseId,
    required this.userId,
  });

  @override
  State<AppealCasePage> createState() => _AppealCasePageState();
}

class _AppealCasePageState extends State<AppealCasePage> {
  final TextEditingController reasonController = TextEditingController();

  bool loading = true;
  bool submitting = false;
  AppealCase? existingAppeal;

  late CaseAppealService service;

  @override
  void initState() {
    super.initState();
    service = CaseAppealService(widget.token);
    _loadAppeal();
  }

  Future<void> _loadAppeal() async {
    try {
      final list = await service.getByCaseId(widget.caseId);

      if (list != null) {
        existingAppeal = list;
        reasonController.text = existingAppeal!.reason;
      }
    } catch (e) {
      print("Appeal load error: $e");
    }

    setState(() => loading = false);
  }

  Future<void> _submit() async {
    if (reasonController.text.trim().isEmpty) return;

    setState(() => submitting = true);

    try {
      if (existingAppeal == null) {
        await service.addAppeal(
          userId: widget.userId,
          caseId: widget.caseId,
          reason: reasonController.text,
        );
      } else {
        await service.updateAppeal(
          appealId: existingAppeal!.id,
          userId: widget.userId,
          caseId: widget.caseId,
          reason: reasonController.text,
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      print("Submit error: $e");
    }

    setState(() => submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          existingAppeal == null ? "Case Appeal" : "Update Appeal",
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Appeal Reason",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter appeal reason",
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitting ? null : _submit,
                child: Text(
                  existingAppeal == null ? "Submit Appeal" : "Update Appeal",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
