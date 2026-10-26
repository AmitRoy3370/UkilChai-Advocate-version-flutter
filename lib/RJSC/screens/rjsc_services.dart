// lib/RJSC/screens/rjsc_compliance_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'rjsc_registration_screen.dart';
import 'my_rjsc_page.dart';    // ✅ নতুন
import 'all_rjsc_page.dart';   // ✅ নতুন
import 'my_rjsc_process_control_screen.dart'; // ✅ NEW

class RjscServices extends StatelessWidget {
  const RjscServices({super.key});

  // ✅ এখন ৪টি অপশন
  final List<Map<String, dynamic>> services = const [
    {
      "title": "RJSC Compliance",
      "subtitle": "Manage your RJSC compliance",
      "icon": Icons.verified_user,
      "color": Color(0xFF0B5D36),
      "action": "rjsc_compliance",
    },
    {
      "title": "My RJSC",
      "subtitle": "View and manage your RJSC filings",
      "icon": Icons.folder_shared,
      "color": Color(0xFF1565C0),
      "action": "my_rjsc",
    },
    {
      "title": "All RJSC",
      "subtitle": "Browse all registered RJSC records",
      "icon": Icons.apartment,
      "color": Color(0xFF00897B),
      "action": "all_rjsc",
    },
    // ✅ NEW: Center-admin-only view of RJSC filings they control
    {
      "title": "My RJSC Processes",
      "subtitle": "Manage RJSC filings you control as center admin",
      "icon": Icons.admin_panel_settings,
      "color": Color(0xFFE65100),
      "action": "my_rjsc_processes",
    },
  ];

  // ============ Handle OnTap ============
  Future<void> _handleTap(BuildContext context, String action) async {
    switch (action) {
      case "rjsc_compliance":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RjscRegistrationScreen(),
          ),
        );
        break;

      case "my_rjsc":
        // ✅ My RJSC পেজে নিয়ে যাবে
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyRjscPage(),
          ),
        );
        break;

      case "all_rjsc":
        // ✅ All RJSC পেজে নিয়ে যাবে
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AllRjscPage(),
          ),
        );
        break;

      // ✅ NEW: My RJSC Processes
      case "my_rjsc_processes":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyRjscProcessControlScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "RJSC Compliance",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final service = services[index];
          return _buildServiceCard(
            context,
            title: service['title'],
            subtitle: service['subtitle'],
            icon: service['icon'],
            color: service['color'],
            action: service['action'],
          );
        },
      ),
    );
  }

  // ============ Service Card ============
  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String action,
  }) {
    return InkWell(
      onTap: () => _handleTap(context, action),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),

            // Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}