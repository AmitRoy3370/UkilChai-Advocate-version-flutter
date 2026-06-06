// lib/Screens/TermsAndPrivacyScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndPrivacyScreen extends StatefulWidget {
  const TermsAndPrivacyScreen({super.key});

  @override
  State<TermsAndPrivacyScreen> createState() => _TermsAndPrivacyScreenState();
}

class _TermsAndPrivacyScreenState extends State<TermsAndPrivacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          _selectedTabIndex == 0 ? "Terms & Conditions" : "Privacy Policy",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E),
                Color(0xFF283593),
                Color(0xFF3949AB),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: "Terms & Conditions"),
                Tab(text: "Privacy Policy"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTermsContent(),
          _buildPrivacyContent(),
        ],
      ),
    );
  }

  Widget _buildTermsContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF283593),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A237E).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Terms & Conditions",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Last Updated: 2024",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1 - About Ukil
          _buildSection(
            number: "1",
            title: "About Ukil",
            content: """
(a) Ukil is a legal-tech platform that facilitates connections between users and independent legal professionals.
(b) Ukil does not itself provide legal advice or legal representation unless expressly stated.
(c) All legal services are provided by independent advocates, and Ukil acts solely as a technology and service facilitation platform.
""",
          ),
          const SizedBox(height: 16),

          // Section 2 - Eligibility
          _buildSection(
            number: "2",
            title: "Eligibility",
            content: """
To use Ukil, you must:
(a) Be at least 18 years of age;
(b) Provide accurate, current, and complete registration information;
(c) Use the platform only for lawful purposes.

Ukil reserves the right to refuse service or terminate access to users who fail to meet these requirements.
""",
          ),
          const SizedBox(height: 16),

          // Section 3 - User Responsibilities
          _buildSection(
            number: "3",
            title: "User Responsibilities",
            content: """
Users agree to:
(a) Provide true and accurate information;
(b) Maintain the confidentiality of their login credentials;
(c) Use the platform respectfully and ethically;
(d) Refrain from engaging in fraud, harassment, abuse, or unlawful activity.

Ukil may suspend or terminate accounts for any violation of these obligations.
""",
          ),
          const SizedBox(height: 16),

          // Section 4 - Role of Lawyers
          _buildSection(
            number: "4",
            title: "Role of Lawyers",
            content: """
(a) Lawyers listed on Ukil are independent professionals, not employees or agents of Ukil.
(b) Ukil does not guarantee legal outcomes or results.
(c) Responsibility for legal advice, representation, and conduct rests solely with the engaged lawyer.
""",
          ),
          const SizedBox(height: 16),

          // Section 5 - Payments & Fees
          _buildSection(
            number: "5",
            title: "Payments & Fees",
            content: """
(a) Ukil may charge service fees, subscription fees, or commissions, as clearly stated on the platform.
(b) Payments may be processed through third-party payment gateways.
(c) Unless otherwise stated, all payments are non-refundable.
(d) Ukil is not responsible for disputes between users and lawyers regarding professional fees.
""",
          ),
          const SizedBox(height: 16),

          // Section 6 - Data & Privacy
          _buildSection(
            number: "6",
            title: "Data & Privacy",
            content: """
(a) Ukil collects and processes personal data in accordance with its Privacy Policy.
(b) By using Ukil, users consent to such collection and processing.
(c) Users are responsible for reviewing and understanding the Privacy Policy.
""",
          ),
          const SizedBox(height: 16),

          // Section 7 - Confidentiality
          _buildSection(
            number: "7",
            title: "Confidentiality",
            content: """
(a) Ukil takes reasonable measures to protect user information.
(b) However, users acknowledge that no digital system is entirely secure.
(c) Users should avoid sharing sensitive personal or legal information unnecessarily.
""",
          ),
          const SizedBox(height: 16),

          // Section 8 - Limitation of Liability
          _buildSection(
            number: "8",
            title: "Limitation of Liability",
            content: """
To the fullest extent permitted by law:
(a) Ukil shall not be liable for any loss, damage, or harm arising from legal services provided by third-party lawyers;
(b) Ukil shall not be liable for technical failures, service interruptions, or data loss beyond reasonable control;
(c) Ukil shall not be responsible for decisions made by users based on information obtained through the platform.
""",
          ),
          const SizedBox(height: 16),

          // Section 9 - Intellectual Property
          _buildSection(
            number: "9",
            title: "Intellectual Property",
            content: """
(a) All content, logos, trademarks, and software related to Ukil are the property of Ukil unless otherwise stated.
(b) Users may not reproduce, distribute, modify, or use any content without prior written consent.
""",
          ),
          const SizedBox(height: 16),

          // Section 10 - Account Suspension & Termination
          _buildSection(
            number: "10",
            title: "Account Suspension & Termination",
            content: """
(a) Ukil may suspend or terminate user accounts for:
   (i) Violation of these Terms;
   (ii) Misuse of the platform;
   (iii) Engagement in unlawful activities.
(b) Termination does not affect any accrued rights or obligations.
""",
          ),
          const SizedBox(height: 16),

          // Section 11 - Amendments to Terms
          _buildSection(
            number: "11",
            title: "Amendments to Terms",
            content: """
(a) Ukil reserves the right to modify these Terms & Conditions at any time.
(b) Updated terms will be posted on the platform.
(c) Continued use of Ukil constitutes acceptance of the revised Terms.
""",
          ),
          const SizedBox(height: 16),

          // Section 12 - Governing Law & Jurisdiction
          _buildSection(
            number: "12",
            title: "Governing Law & Jurisdiction",
            content: """
(a) These Terms & Conditions shall be governed by and interpreted in accordance with the laws of Bangladesh.
(b) Any dispute arising from these Terms shall be subject to the exclusive jurisdiction of the courts of Bangladesh.
""",
          ),
          const SizedBox(height: 16),

          // Section 13 - Contact Information
          _buildContactSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPrivacyContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF283593),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A237E).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Privacy Policy",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Last Updated: 2024",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1 - Information We Collect
          _buildPrivacySection(
            number: "1",
            title: "Information We Collect",
            content: """
We may collect the following categories of information:

(a) Personal Information:
   • Full name
   • Phone number
   • Email address
   • Address and location details
   • National ID or verification documents (if applicable)

(b) Case & Service Information:
   • Case details submitted by users
   • Communication between users and legal professionals
   • Court-related updates and procedural data

(c) Technical Information:
   • IP address
   • Device and browser information
   • Log files and usage data
""",
          ),
          const SizedBox(height: 16),

          // Section 2 - Use of Information
          _buildPrivacySection(
            number: "2",
            title: "Use of Information",
            content: """
Ukil uses collected information for the following purposes:
(a) To provide and maintain our services
(b) To connect users with verified legal professionals
(c) To manage communication and case progress
(d) To process payments, subscriptions, and service fees
(e) To send service-related notifications
(f) To improve platform security and prevent misuse
""",
          ),
          const SizedBox(height: 16),

          // Section 3 - Disclosure of Information
          _buildPrivacySection(
            number: "3",
            title: "Disclosure of Information",
            content: """
Ukil does not sell personal data. Information may be disclosed only in the following circumstances:
(a) To lawyers or service providers for service delivery
(b) To comply with legal or regulatory obligations
(c) To protect the rights, safety, and property of Ukil and its users
(d) With the explicit consent of the user
""",
          ),
          const SizedBox(height: 16),

          // Section 4 - Data Protection & Security
          _buildPrivacySection(
            number: "4",
            title: "Data Protection & Security",
            content: """
Ukil implements reasonable technical and organizational safeguards, including:
(a) Secure servers and encrypted communications
(b) Restricted access to sensitive information
(c) Regular monitoring of systems

However, users acknowledge that no digital system guarantees absolute security.
""",
          ),
          const SizedBox(height: 16),

          // Section 5 - Confidentiality of Legal Information
          _buildPrivacySection(
            number: "5",
            title: "Confidentiality of Legal Information",
            content: """
Given the sensitive nature of legal data, Ukil ensures that:
(a) Case information is accessible only to authorized persons
(b) Staff and Court Ambassadors follow strict confidentiality obligations
(c) Information is handled ethically and professionally
""",
          ),
          const SizedBox(height: 16),

          // Section 6 - Cookies & Tracking Technologies
          _buildPrivacySection(
            number: "6",
            title: "Cookies & Tracking Technologies",
            content: """
Ukil may use cookies to:
(a) Enhance user experience
(b) Analyze platform usage
(c) Store user preferences

Users may disable cookies via browser settings; however, certain features may not function properly.
""",
          ),
          const SizedBox(height: 16),

          // Section 7 - User Rights
          _buildPrivacySection(
            number: "7",
            title: "User Rights",
            content: """
Subject to applicable law, users have the right to:
(a) Access their personal data
(b) Request correction of inaccurate information
(c) Request deletion of their account, where legally permissible
(d) Withdraw consent for data processing

Requests may be sent to info@ukil.com.bd.
""",
          ),
          const SizedBox(height: 16),

          // Section 8 - Data Retention
          _buildPrivacySection(
            number: "8",
            title: "Data Retention",
            content: """
Ukil retains information only for as long as necessary to:
(a) Provide services
(b) Comply with legal and regulatory requirements
(c) Resolve disputes and enforce agreements

After the retention period, data is securely deleted or anonymized.
""",
          ),
          const SizedBox(height: 16),

          // Section 9 - Children's Privacy
          _buildPrivacySection(
            number: "9",
            title: "Children's Privacy",
            content: """
(a) Ukil services are intended for users aged 18 years or above.
(b) We do not knowingly collect personal data from minors.
""",
          ),
          const SizedBox(height: 16),

          // Section 10 - Third-Party Links
          _buildPrivacySection(
            number: "10",
            title: "Third-Party Links",
            content: """
(a) Ukil may contain links to third-party websites.
(b) Ukil is not responsible for the privacy practices or content of such external platforms.
""",
          ),
          const SizedBox(height: 16),

          // Section 11 - Amendments to This Policy
          _buildPrivacySection(
            number: "11",
            title: "Amendments to This Policy",
            content: """
(a) Ukil reserves the right to modify this Privacy Policy at any time.
(b) Updates will be published on this page.
(c) Continued use of the platform constitutes acceptance of the revised policy.
""",
          ),
          const SizedBox(height: 16),

          // Section 12 - Governing Law
          _buildPrivacySection(
            number: "12",
            title: "Governing Law",
            content: """
This Privacy Policy shall be governed by and interpreted in accordance with the laws of Bangladesh.
""",
          ),
          const SizedBox(height: 16),

          // Section 13 - Contact Information
          _buildPrivacyContactSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E),
            Color(0xFF283593),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "13. Contact Information",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.email,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "info@ukil.com.bd",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.language,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "www.ukil.com.bd",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyContactSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E),
            Color(0xFF283593),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "13. Contact Information",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.email,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "info@ukil.com.bd",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.language,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "www.ukil.com.bd",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}