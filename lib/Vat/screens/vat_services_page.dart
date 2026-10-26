// lib/vat/screens/vat_services_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'vat_registration_page.dart';
import 'my_vat_page.dart';
import 'all_vat_page.dart';
import 'my_vat_process_control_page.dart'; // ✅ NEW

class VatServicesPage extends StatelessWidget {
  const VatServicesPage({super.key});

  // ✅ 4 service options
  final List<Map<String, dynamic>> services = const [
    {
      'title': 'VAT Registration',
      'subtitle': 'Register your business for VAT',
      'icon': Icons.receipt_long,
      'color': Color(0xFF1565C0),
      'action': 'vat_registration',
    },
    {
      'title': 'My VAT',
      'subtitle': 'View your approved and pending VAT',
      'icon': Icons.folder_shared,
      'color': Color(0xFF00897B),
      'action': 'my_vat',
    },
    {
      'title': 'All VAT',
      'subtitle': 'Browse all registered VAT records',
      'icon': Icons.apartment,
      'color': Color(0xFF6A1B9A),
      'action': 'all_vat',
    },
    {
      'title': 'My VAT Processes',
      'subtitle': 'Manage VAT filings assigned to you',
      'icon': Icons.assignment_ind,
      'color': Color(0xFF0B5D36),
      'action': 'my_vat_processes',
    },
  ];

  Future<void> _handleTap(BuildContext context, String action) async {
    switch (action) {
      case 'vat_registration':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VatRegistrationPage(),
          ),
        );
        break;

      case 'my_vat':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyVatPage(),
          ),
        );
        break;

      case 'all_vat':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AllVatPage(),
          ),
        );
        break;

      case 'my_vat_processes':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyVatProcessControlPage(),
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
          'VAT Services',
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
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