// lib/TradeLicense/screens/trade_license_service_selection_screen.dart

import 'package:flutter/material.dart';
import 'trade_license_registration_screen.dart';
import 'my_trade_license_screen.dart';
import 'all_trade_license_screen.dart';
import 'my_trade_license_process_control_screen.dart'; // ✅ NEW

class TradeLicenseServiceSelectionScreen extends StatelessWidget {
  const TradeLicenseServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Trade License Services',
            style: TextStyle(color: Colors.black87, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _card(
                context,
                icon: Icons.add_business,
                color: const Color(0xFF1E7A3A),
                title: 'Register Trade License',
                subtitle:
                    'Apply for a new trade license with required documents',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TradeLicenseRegistrationScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _card(
                context,
                icon: Icons.folder_special,
                color: const Color(0xFF2E7D32),
                title: 'My Trade License',
                subtitle:
                    'View your registered and pending trade license applications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyTradeLicenseScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _card(
                context,
                icon: Icons.public,
                color: const Color(0xFF6A1B9A),
                title: 'All Trade License',
                subtitle:
                    'Browse all approved trade licenses nationwide',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AllTradeLicenseScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ✅ NEW: My Trade License Processes
              _card(
                context,
                icon: Icons.assignment_ind,
                color: const Color(0xFF0B5D36),
                title: 'My Trade License Processes',
                subtitle:
                    'Manage trade license filings assigned to you',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MyTradeLicenseProcessControlScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}