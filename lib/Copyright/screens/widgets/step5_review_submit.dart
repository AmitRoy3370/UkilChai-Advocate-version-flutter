// lib/Copyright/screens/widgets/step5_review_submit.dart

import 'package:flutter/material.dart';

class Step5ReviewSubmit extends StatelessWidget {
  final String typeOfWork;
  final String titleOfWork;
  final String author;
  final String applicantName;
  final int documentCount;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final bool isUpdateMode;

  const Step5ReviewSubmit({
    super.key,
    required this.typeOfWork,
    required this.titleOfWork,
    required this.author,
    required this.applicantName,
    required this.documentCount,
    required this.isSubmitting,
    required this.onBack,
    required this.onSubmit,
    required this.isUpdateMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review & Submit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Application Summary',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            _row('Work Title', titleOfWork.isEmpty ? '-' : titleOfWork),
            _row('Type of Work', typeOfWork.isEmpty ? '-' : typeOfWork),
            _row('Author', author.isEmpty ? '-' : author),
            _row('Applicant', applicantName.isEmpty ? '-' : applicantName),
            _row('Documents', '$documentCount Uploaded'),

            const Divider(height: 32),

            const SizedBox(height: 8),
            if (isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E7A3A), // green
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isUpdateMode ? 'Update Application' : 'Submit Application',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isSubmitting ? null : onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: Colors.black87,
              ),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}