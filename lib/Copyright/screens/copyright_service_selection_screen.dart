// lib/Copyright/screens/copyright_service_selection_screen.dart

import 'package:flutter/material.dart';
import 'copyright_registration_screen.dart';
import 'my_copyright_screen.dart';
import 'all_copyright_screen.dart';
import 'copyright_process_control_screen.dart'; // ✅ NEW

class CopyrightServiceSelectionScreen extends StatelessWidget {
  const CopyrightServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Copyright Services',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _serviceCard(
                context,
                icon: Icons.copyright,
                iconColor: const Color(0xFF1A3FBF),
                title: 'Register Copyright',
                subtitle:
                    'Protect your original work with legal copyright registration',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CopyrightRegistrationScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _serviceCard(
                context,
                icon: Icons.folder_special,
                iconColor: const Color(0xFF2E7D32),
                title: 'My Copyright',
                subtitle:
                    'View your registered and pending copyright applications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyCopyrightScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _serviceCard(
                context,
                icon: Icons.public,
                iconColor: const Color(0xFF6A1B9A),
                title: 'All Copyright',
                subtitle:
                    'Browse all approved copyright registrations nationwide',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AllCopyrightScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ NEW: My Copyright Processes (Center Admin)
              _serviceCard(
                context,
                icon: Icons.admin_panel_settings,
                iconColor: const Color(0xFFE65100),
                title: 'My Copyright Processes',
                subtitle:
                    'Manage copyright registrations you are handling as a center admin',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CopyrightProcessControlScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
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
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}