import 'package:flutter/material.dart';
import '../DirectorsPages/DirectorRegistrationScreen.dart';
import '../ShareholderPages/shareholder_registration_screen.dart';
import '../CompanyPages/company_registration_screen.dart';
import '../CompanyPages/company_services_page.dart';
import '../DirectorsPages/director_profile_page.dart';
import '../ShareholderPages/shareholder_profile_page.dart';
import '../DirectorsPages/director_list_page.dart';
import '../ShareholderPages/shareholder_list_page.dart';
import '../Copyright/screens/copyright_service_selection_screen.dart';
import '../RJSC/screens/rjsc_services.dart';
import '../TradeLicense/screens/trade_license_service_selection_screen.dart';
import '../Trademark/screens/trademark_service_selection_screen.dart';
import '../Tin/screens/tin_service_selection_screen.dart';
import '../Vat/screens/vat_services_page.dart';

class SelectionPage extends StatelessWidget {
  const SelectionPage({super.key});

  // আপনার দেওয়া ১৩টি অপশন
  final List<Map<String, dynamic>> services = const [
    {
      "title": "Company Registration",
      "icon": Icons.business,
      "subtitle": "Register your new company"
    },
    {
      "title": "Trade Licences",
      "icon": Icons.card_membership,
      "subtitle": "Get your trade license"
    },
    {
      "title": "Startup Package",
      "icon": Icons.rocket_launch,
      "subtitle": "Complete startup solution"
    },
    {
      "title": "Anual Return",
      "icon": Icons.calendar_month,
      "subtitle": "File your annual return"
    },
    {
      "title": "Partnerships Registration",
      "icon": Icons.handshake,
      "subtitle": "Register your partnership"
    },
    {
      "title": "Legal Notice Drafting",
      "icon": Icons.gavel,
      "subtitle": "Draft legal notices"
    },
    {
      "title": "Contract Drafting",
      "icon": Icons.description,
      "subtitle": "Professional contract drafting"
    },
    {
      "title": "TIN",
      "icon": Icons.receipt_long,
      "subtitle": "Tax Identification Number"
    },
    {
      "title": "BIN",
      "icon": Icons.numbers,
      "subtitle": "Business Identification Number"
    },
    {
      "title": "Copyright",
      "icon": Icons.copyright,
      "subtitle": "Protect your copyright"
    },
    {
      "title": "Rjsc",
      "icon": Icons.account_balance,
      "subtitle": "RJSC related services"
    },
    {
      "title": "VAT",
      "icon": Icons.percent,
      "subtitle": "VAT registration & filing"
    },
    {
      "title": "Trademark",
      "icon": Icons.verified,
      "subtitle": "Register your trademark"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // হালকা ব্যাকগ্রাউন্ড
      appBar: AppBar(
        title: const Text(
          "Select a Service",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final service = services[index];
          return _buildServiceCard(
            context,
            service["title"],
            service["subtitle"],
            service["icon"],
          );
        },
      ),
    );
  }

  // সুন্দর কার্ড তৈরির ফাংশন
  Widget _buildServiceCard(
      BuildContext context, String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () {
        // ✅ "Company Registration" ক্লিক করলে CompanyServicesPage এ যাবে
        if (title == "Company Registration") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CompanyServicesPage(),
            ),
          );
          return;
        } else if(title == "Rjsc") {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RjscServices(),
            ),
          );

        } else if(title == "Copyright") {


          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CopyrightServiceSelectionScreen(),
            ),
          );

        } else if(title == "Trade Licences") {


          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TradeLicenseServiceSelectionScreen(),
            ),
          );

        } else if(title == "Trademark") {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TrademarkServiceSelectionScreen(),
            ),
          );

        } else if(title == "TIN") {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TinServiceSelectionScreen(),
            ),
          );

        } else if(title == "VAT") {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VatServicesPage(),
            ),
          );

        }

        // বাকি সব service এ ক্লিক করলে Coming soon SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title — Coming soon'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF0B5D36),
          ),
        );
      },
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
            // বাম দিকের আইকন বক্স
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF0B5D36).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 28,
                color: const Color(0xFF0B5D36),
              ),
            ),
            const SizedBox(width: 16),

            // মাঝখানের টেক্সট (Title এবং Subtitle)
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

            // ডান দিকের এরো আইকন
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