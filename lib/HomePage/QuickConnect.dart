// QuickConnect.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASE_URL;
import 'package:advocatechaiadvocate/PageTransition.dart';
import 'package:advocatechaiadvocate/Auth/AuthService.dart';
import 'package:advocatechaiadvocate/LogInPage/LogIn.dart';

// You may need to adjust these import paths to match your project's directory structure
import '../CaseRelatedPages/case_request.dart';
import '../CaseRelatedPages/CaseHomePage.dart';
import '../ChatRelatedPages/CenterAdminChatListScreen.dart';
import '../ChatRelatedPages/AllUserChatListScreen.dart';
import '../CaseRelatedPages/see_my_requested_Case_to_fight.dart';
import 'QuickCard.dart';

class QuickConnect extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;

  /// When true, the section tries to fill the remaining viewport space
  /// given by the parent via [remainingViewportHeight].
  final bool fillHeight;

  /// Explicit height to fill (in logical pixels). Used only when
  /// [fillHeight] is true. Ignored otherwise.
  final double? remainingViewportHeight;

  const QuickConnect({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    this.fillHeight = false,
    this.remainingViewportHeight,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenW = size.width;
    final screenH = size.height;

    // ── Grid config ──
    const int columns = 2;
    const int rows = 2;

    // ✅ Tighter spacing between cards
    final double crossSpacing = (screenW * 0.02).clamp(6, 12);
    final double mainSpacing = (screenW * 0.015).clamp(5, 10);

    // ── Header metrics ──
    final double headerBarHeight = (screenW * 0.055).clamp(20, 26);
    final double titleFontSize = (screenW * 0.05).clamp(18, 24);
    final double subtitleFontSize = (screenW * 0.032).clamp(11, 14);
    final double titleRowHeight = titleFontSize * 1.3;
    final double subtitleRowHeight = subtitleFontSize * 1.3;
    final double gapAfterTitle = (screenW * 0.01).clamp(4, 8);
    final double gapBeforeGrid = (screenW * 0.02).clamp(10, 16);

    final double effectiveHeaderHeight =
        titleRowHeight > headerBarHeight ? titleRowHeight : headerBarHeight;

    final double headerBlock = effectiveHeaderHeight +
        gapAfterTitle +
        subtitleRowHeight +
        gapBeforeGrid;

    // ── Card height decision ──
    late final double cardHeight;

    if (fillHeight && remainingViewportHeight != null) {
      final double gridArea = remainingViewportHeight! - headerBlock;
      cardHeight = ((gridArea - mainSpacing) / rows).clamp(160.0, 260.0);
    } else {
      cardHeight = (screenH * 0.20).clamp(160.0, 200.0);
    }

    final double? sectionHeight = fillHeight
        ? headerBlock + (cardHeight * rows) + mainSpacing
        : null;

    return SizedBox(
      height: sectionHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                width: 4,
                height: headerBarHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: (screenW * 0.03).clamp(10, 14)),
              Text(
                "Quick Connect",
                style: GoogleFonts.poppins(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: gapAfterTitle),
          Padding(
            padding: EdgeInsets.only(left: (screenW * 0.04).clamp(14, 18)),
            child: Text(
              "Get instant legal assistance",
              style: GoogleFonts.inter(
                fontSize: subtitleFontSize,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: gapBeforeGrid),

          // ── Grid ──
          if (fillHeight)
            Expanded(
              child: GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: crossSpacing,
                  mainAxisSpacing: mainSpacing,
                  mainAxisExtent: cardHeight,
                ),
                children: _buildCards(context),
              ),
            )
          else
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: crossSpacing,
                mainAxisSpacing: mainSpacing,
                mainAxisExtent: cardHeight,
              ),
              children: _buildCards(context),
            ),
        ],
      ),
    );
  }

  // ── Card list (Ordered as requested) ──
  List<Widget> _buildCards(BuildContext context) => [
        // 1. Case Requests
        QuickCard(
          icon: Icons.gavel,
          title: "Case Requests",
          subtitle: "Review your requested cases",
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)], // Deep Navy
          ),
          onTap: () async => _handleCaseRequests(context),
        ),
        // 2. Messages
        QuickCard(
          icon: Icons.chat_bubble_outline,
          title: "Messages",
          subtitle: "View admin messages",
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0)], // Royal Blue
          ),
          onTap: () async => _handleMessages(context),
        ),
        // 3. My Cases
        QuickCard(
          icon: Icons.folder_shared,
          title: "My Cases",
          subtitle: "View your case details",
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)], // Professional Green
          ),
          onTap: () async => _handleMyCases(context),
        ),
        // 4. Chats
        QuickCard(
          icon: Icons.forum,
          title: "Chats",
          subtitle: "Chat with other users",
          gradient: const LinearGradient(
            colors: [Color(0xFF263238), Color(0xFF37474F)], // Dark Slate
          ),
          onTap: () async => _handleChats(context),
        ),
      ];

  // ═══════════════════════════════════════════════════════════════════
  // HANDLERS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _navigateWithTransition(
      BuildContext context, Widget page) async {
    final token = await AuthService.getToken();
    if (token == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LogIn()));
    } else {
      NavigationHelper.push(
        context,
        page,
        transitionType: await AnimatedRoute.getRandomSafeAnimation(),
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  // 1. Case Requests
  Future<void> _handleCaseRequests(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString("userId") ?? "";

    if (userId.isEmpty) {
      _showLoginRequired(context);
      return;
    }

    // Using SeeMyRequestedCaseToFightListPage (from your provided code)
    // Note: Adjust the import path if your file name differs.
    _navigateWithTransition(
      context,
      SeeMyRequestedCaseToFightListPage(), 
    );
  }

  // 2. Messages (Center Admin Chats)
  Future<void> _handleMessages(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString("userId") ?? "";
    String token = prefs.getString("jwt_token") ?? "";

    if (userId.isEmpty || token.isEmpty) {
      _showLoginRequired(context);
      return;
    }

    final response = await http.get(
      Uri.parse('${BASE_URL.Urls().baseURL}user/search?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _navigateWithTransition(
        context,
        CenterAdminChatListScreen(
          currentUserId: userId,
          currentUserName: data['name'] ?? "User",
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to fetch user data."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 3. My Cases
  Future<void> _handleMyCases(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString("userId") ?? "";

    if (userId.isEmpty) {
      _showLoginRequired(context);
      return;
    }

    _navigateWithTransition(
      context,
      const CaseHomePage(),
    );
  }

  // 4. Chats (All Users)
  Future<void> _handleChats(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString("userId") ?? "";
    String token = prefs.getString("jwt_token") ?? "";

    if (userId.isEmpty || token.isEmpty) {
      _showLoginRequired(context);
      return;
    }

    final response = await http.get(
      Uri.parse('${BASE_URL.Urls().baseURL}user/search?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _navigateWithTransition(
        context,
        AllUserChatListScreen(
          currentUserId: userId,
          currentUserName: data['name'] ?? "User",
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to fetch user data."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoginRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please log in to continue"),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }
}