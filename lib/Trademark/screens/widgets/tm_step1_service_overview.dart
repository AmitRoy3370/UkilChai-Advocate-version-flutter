// lib/Trademark/screens/widgets/tm_step1_service_overview.dart

import 'package:flutter/material.dart';

class TmStep1ServiceOverview extends StatelessWidget {
  final VoidCallback onApplyNow;

  const TmStep1ServiceOverview({super.key, required this.onApplyNow});

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
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF6A1B9A),
              ),
              child: const Icon(Icons.verified,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Trademark Registration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Register your brand name, logo or slogan and protect your intellectual property under trademark law.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _bullet(Icons.public, 'Class Selection'),
            _bullet(Icons.shield, 'Logo Protection'),
            _bullet(Icons.verified_user, 'Legal Ownership'),
            _bullet(Icons.workspace_premium, 'Nationwide Protection'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onApplyNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
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
          Icon(icon, size: 18, color: const Color(0xFF6A1B9A)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}