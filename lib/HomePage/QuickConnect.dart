import 'dart:convert';
import '../ChatRelatedPages/CenterAdminChatListScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/AuthService.dart';
import '../Auth/AuthGate.dart';
import '../CaseRelatedPages/CaseHomePage.dart';
import '../CaseRelatedPages/MyCasesPage.dart';
import '../QuestionPages/AskQuestionPage.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import '../LogInPage/LogIn.dart';
import './QuickCard.dart';
import '../AdvocatePages/advocate_home_page_pageview.dart';
import '../PageTransition.dart';

class QuickConnect extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;

  const QuickConnect({
    super.key,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    final childAspectRatio = isDesktop ? 1.1 : 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Quick Connect",
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            "Get instant legal assistance",
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 16 : 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Animated Grid
        GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isDesktop ? 24 : 16,
          mainAxisSpacing: isDesktop ? 24 : 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: [
            QuickCard(
              icon: Icons.person_search,
              title: "Find Expert",
              subtitle: "Connect with specialized advocates",
              gradient: const LinearGradient(
                // Deep Navy - Trust & Authority
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
              ),
              // Browsing advocates is public — no login required.
              onTap: () =>
                  _navigateWithTransition(context, const AdvocateHomePage()),
            ),
            QuickCard(
              icon: Icons.chat_bubble_outline,
              title: "Free Consult",
              subtitle: "15-min free consultation",
              gradient: const LinearGradient(
                // Royal Blue - Confidence
                colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
              ),
              onTap: () async => await _handleFreeConsult(context),
            ),
            QuickCard(
              icon: Icons.help_outline_rounded,
              title: "Ask Question",
              subtitle: "Public Q&A with advocates",
              gradient: const LinearGradient(
                // Professional Green
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              ),
              onTap: () async => await _handleAskQuestion(context),
            ),
            QuickCard(
              icon: Icons.calendar_month,
              title: "My Cases",
              subtitle: "View your case details",
              gradient: const LinearGradient(
                // Dark Slate
                colors: [Color(0xFF263238), Color(0xFF37474F)],
              ),
              onTap: () async => await _handleMyCases(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _navigateWithTransition(
      BuildContext context, Widget page) async {
    NavigationHelper.push(
      context,
      page,
      transitionType: await AnimatedRoute.getRandomSafeAnimation(),
      duration: const Duration(milliseconds: 500),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LOGIN GATE HELPER
  // Returns true if user is logged in (or just logged in successfully).
  // ═══════════════════════════════════════════════════════════════════
  Future<bool> _ensureLoggedIn(BuildContext context) async {
    final loggedIn = await AuthGate.isLoggedIn();
    if (loggedIn) return true;

    if (!context.mounted) return false;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LogIn()),
    );
    return result == true;
  }

  // ═══════════════════════════════════════════════════════════════════
  // FREE CONSULT
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _handleFreeConsult(BuildContext context) async {
    final ok = await _ensureLoggedIn(context);
    if (!ok || !context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "";
    final token = prefs.getString("jwt_token") ?? "";

    if (userId.isEmpty || token.isEmpty) {
      _showLoginRequired(context);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${BASE_URL.Urls().baseURL}user/search?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _navigateWithTransition(
          context,
          CenterAdminChatListScreen(
            currentUserId: userId,
            currentUserName: data['name'] ?? "User",
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to fetch user data. Please log in again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // ASK QUESTION
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _handleAskQuestion(BuildContext context) async {
    final ok = await _ensureLoggedIn(context);
    if (!ok || !context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "";

    if (userId.isEmpty) {
      _showLoginRequired(context);
      return;
    }

    await _navigateWithTransition(context, AskQuestionPage(userId: userId));
  }

  // ═══════════════════════════════════════════════════════════════════
  // MY CASES
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _handleMyCases(BuildContext context) async {
    final ok = await _ensureLoggedIn(context);
    if (!ok || !context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId") ?? "";

    if (userId.isEmpty) {
      _showLoginRequired(context);
      return;
    }

    await _navigateWithTransition(context, const CaseHomePage());
  }

  void _showLoginRequired(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please log in to continue"),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }
}