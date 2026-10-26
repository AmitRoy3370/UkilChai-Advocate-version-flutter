// lib/CompanyPages/company_services_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Auth/AuthService.dart';

// ✅ আপনার main.dart থেকে এই পেজগুলোর import
import 'company_registration_screen.dart';
import 'my_company_page.dart';
import 'all_companies_page.dart';              // ✅ নতুন — See All Companies এর জন্য
import 'company_process_control_screen.dart';  // ✅ NEW — My Company Processes
import '../DirectorsPages/director_list_page.dart';
import '../ShareholderPages/shareholder_list_page.dart';
import '../LogInPage/LogIn.dart';

class CompanyServicesPage extends StatelessWidget {
  const CompanyServicesPage({super.key});

  // ✅ এখন ৬টি অপশন
  final List<Map<String, dynamic>> services = const [
    {
      "title": "Company Registration",
      "subtitle": "Register your new company",
      "icon": Icons.business,
      "color": Color(0xFF0B5D36),
      "action": "register_company",
    },
    {
      "title": "My Companies",
      "subtitle": "View and manage your companies",
      "icon": Icons.business_center,
      "color": Color(0xFF1565C0),
      "action": "my_companies",
    },
    {
      "title": "See All Companies",
      "subtitle": "Browse all registered companies",
      "icon": Icons.apartment,
      "color": Color(0xFF00897B),
      "action": "all_companies",
    },
    {
      "title": "See All Directors",
      "subtitle": "Browse all registered directors",
      "icon": Icons.people,
      "color": Color(0xFF6A1B9A),
      "action": "all_directors",
    },
    {
      "title": "See All Shareholders",
      "subtitle": "Browse all registered shareholders",
      "icon": Icons.people_outline,
      "color": Color(0xFFC62828),
      "action": "all_shareholders",
    },
    // ✅ NEW: Center-Admin-only view of companies they control
    {
      "title": "My Company Processes",
      "subtitle": "Manage company registrations you control as center admin",
      "icon": Icons.admin_panel_settings,
      "color": Color(0xFFE65100),
      "action": "my_company_processes",
    },
  ];

  // ============ Handle OnTap ============
  Future<void> _handleTap(BuildContext context, String action) async {
    // ✅ Token check — লগইন না থাকলে LogIn এ পাঠাবে
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      if (!context.mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LogIn()),
      );
      if (result == true && context.mounted) {
        // লগইন সফল হলে আবার চেষ্টা করুন
        _handleTap(context, action);
      }
      return;
    }

    // ✅ userId বের করুন
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null || userId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    // ✅ Action অনুযায়ী navigate
    switch (action) {
      case 'register_company':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyRegistrationScreen(userId: userId),
          ),
        );
        break;

      case 'my_companies':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyCompanyPage()),
        );
        break;

      case 'all_companies':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AllCompaniesPage()),
        );
        break;

      case 'all_directors':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DirectorListPage()),
        );
        break;

      case 'all_shareholders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShareholderListPage()),
        );
        break;

      // ✅ NEW: My Company Processes
      case 'my_company_processes':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CompanyProcessControlScreen(),
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
          "Company Services",
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