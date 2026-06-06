import 'package:advocatechaiadvocate/HomePage/AdvocateList.dart';
import 'package:advocatechaiadvocate/HomePage/QuickConnect.dart';
import 'package:advocatechaiadvocate/PostRelatedPages/post_feed_page_home_page.dart';
import 'package:advocatechaiadvocate/PostRelatedPages/post_feed_page.dart';
import 'package:advocatechaiadvocate/AdvocatePages/AdvocateFilterPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'HomePage/SearchScreen.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/CaseHomePage.dart';

import 'NotificationPages/notification_socket_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }
}

class HomeScreenState extends State<Homepage> {
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
                MaterialPageRoute(builder: (_) => const AdvocateFilterPage()),
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
}