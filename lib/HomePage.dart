import 'package:advocatechaiadvocate/HomePage/AdvocateList.dart';
import 'package:advocatechaiadvocate/HomePage/QuickConnect.dart';
import 'package:advocatechaiadvocate/PostRelatedPages/post_feed_page_home_page.dart';
import 'package:advocatechaiadvocate/PostRelatedPages/post_feed_page.dart';
//import 'package:advocatechaiadvocate/AdvocatePages/AdvocateFilterPage.dart';
import 'package:advocatechaiadvocate/AdvocatePages/advocate_home_page_pageview.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Utils/BaseURL.dart' as BASE_URL;
import 'package:http/http.dart' as http;
import 'LifeCycles/PresenceSocketService.dart';
import 'HomePage/SearchScreen.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/CaseHomePage.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../Auth/AuthService.dart';

import 'NotificationPages/notification_socket_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }
}

class HomeScreenState extends State<Homepage> {


  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    heartbit();

  }

  Future<void> heartbit() async {

      final userId = await AuthService.getUserId();
      
      if(userId != null) {

         _startHeartbeat(userId!);

      }

  }

  void _startHeartbeat(String userId) {
    _heartbeatTimer = Timer.periodic(
    const Duration(seconds: 20),
    (timer) async {
       try {
      // ✅ Direct heartbeat by userId
      final url = Uri.parse("${BASE_URL.Urls().baseURL}user-active/heartbeat/$userId");
      
      final token = await AuthService.getToken();

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        //_lastHeartbeatTime = DateTime.now();
        //print("💓 Heartbeat sent at ${_lastHeartbeatTime?.toLocal()}");
      } else {
        print("❌ Heartbeat failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Heartbeat error: $e");
    }
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isTablet = screenWidth > 600 && screenWidth <= 800;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade50,
            Colors.white,
            Colors.green.shade50,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
              vertical: 20,
            ),
            child: Column(
              children: [
                _buildWelcomeBanner(
                  context,
                  isDesktop,
                  isTablet,
                ),

                _buildAdvocatePromotionCard(),

                const SizedBox(height: 24),

                const SizedBox(height: 20),
                QuickConnect(
                  key: UniqueKey(),
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(
                  "Recent Legal Updates",
                  Icons.newspaper,
                ),
                const SizedBox(height: 16),
                PostFeedPageHomePage(
                  key: UniqueKey(),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(
                  "Featured Advocates",
                  Icons.star,
                ),
                const SizedBox(height: 16),
                AdvocateList(
                  key: UniqueKey(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 24,
        vertical: isDesktop ? 32 : 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade700,
            Colors.green.shade500,
            Colors.green.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.gavel,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Welcome to উকিল চাই",
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop
                        ? 28
                        : (isTablet ? 24 : 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Your trusted legal partner. Connect with clients, manage cases, and provide expert legal advice efficiently.",
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 16 : 14,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade400,
                Colors.green.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (title == 'Featured Advocates') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdvocateHomePage()),
              );
            } else if (title == 'Recent Legal Updates') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostFeedPage()),
              );
            }
          },
          child: Text(
            "See All",
            style: GoogleFonts.inter(
              color: Colors.green.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildAdvocatePromotionCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            Colors.deepPurple.shade600,
            Colors.purple.shade500,
            Colors.blue.shade500,
          ],
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.25),

            blurRadius: 20,

            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.workspace_premium,

              size: 42,

              color: Colors.white,
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "Want to be an User?",

                  style: GoogleFonts.poppins(
                    color: Colors.white,

                    fontSize: 22,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Join our User platform and connect with clients across Bangladesh.",

                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.95),

                    fontSize: 14,

                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://ukil.com.bd');

                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },

                  icon: const Icon(Icons.open_in_new),

                  label: const Text("Visit User App"),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,

                    foregroundColor: Colors.deepPurple,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,

                      vertical: 14,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}