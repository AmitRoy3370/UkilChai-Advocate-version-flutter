// lib/Trademark/screens/widgets/tm_step4_review_submit.dart

import 'package:flutter/material.dart';

class TmStep4ReviewSubmit extends StatelessWidget {
  final String applicationName;
  final String trademarkName;
  final String classOfGoods;
  final String trademarkType;
  final int documentCount;
  final bool isSubmitting;
  final bool isUpdateMode;

  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const TmStep4ReviewSubmit({
    super.key,
    required this.applicationName,
    required this.trademarkName,
    required this.classOfGoods,
    required this.trademarkType,
    required this.documentCount,
    required this.isSubmitting,
    required this.isUpdateMode,
    required this.onBack,
    required this.onSubmit,
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
            _row('Applicant Name', applicationName),
            _row('Trademark Name', trademarkName),
            _row('Class', classOfGoods),
            _row('Trademark Type', trademarkType),
            _row('Documents', '$documentCount Uploaded'),
            const Divider(height: 32),
            if (isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E7A3A),
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
            const SizedBox(height: 10),
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
            width: 120,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}