// lib/Copyright/screens/widgets/step1_service_overview.dart

import 'package:flutter/material.dart';

class Step1ServiceOverview extends StatelessWidget {
  final VoidCallback onApplyNow;

  const Step1ServiceOverview({super.key, required this.onApplyNow});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Big blue circle icon
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A3FBF),
              ),
              child: const Icon(Icons.copyright,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Copyright Registration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Protect your literary, artistic, musical, software, film and other original works.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _bullet(Icons.security, 'Legal Protection'),
            _bullet(Icons.verified_user, 'Proof of Ownership'),
            _bullet(Icons.block, 'Prevent Plagiarism'),
            _bullet(Icons.workspace_premium, 'Lifetime Validity'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onApplyNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3FBF),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Apply Now',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A3FBF)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}