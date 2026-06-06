import 'package:advocatechaiadvocate/Auth/AuthService.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/see_my_requested_Case_to_fight.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../CaseRelatedPages/AddCaseRequestPage.dart';
import 'MyCasesPage.dart';
import 'SeeAllCases.dart';
import 'SeeMyCaseRequest.dart';
import 'case_request_list_page.dart';
import '../PageTransition.dart';

class CaseHomePage extends StatelessWidget {
  const CaseHomePage({super.key});

  // Get random transition type
  Future<PageTransitionType> _getRandomTransition() async {
    return AnimatedRoute.getRandomSafeAnimation();
  }

  // Navigate with random transition
  Future<void> _navigateWithRandomTransition(BuildContext context, Widget page) async {
    NavigationHelper.push(
      context,
      page,
      transitionType: await _getRandomTransition(),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Case Management",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E), // Deep Navy
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF1A237E), // Deep Navy
                Color(0xFF283593), // Indigo
                Color(0xFF3949AB), // Lighter Indigo
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A237E).withOpacity(0.05),
              Colors.white,
              const Color(0xFF1A237E).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Welcome Card
              _buildWelcomeCard(),
              const SizedBox(height: 24),

              // Case Options Grid
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildAnimatedCaseCard(
                      context,
                      title: "Add Case Request",
                      icon: Icons.add_circle_outline,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)], // Royal Blue
                      ),
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId') ?? '';
                        if (userId.isNotEmpty) {
                          _navigateWithRandomTransition(
                            context,
                            AddCaseRequestPage(userId: userId),
                          );
                        }
                      },
                    ),
                    _buildAnimatedCaseCard(
                      context,
                      title: "All Requests",
                      icon: Icons.list_alt,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)], // Green
                      ),
                      onTap: () {
                        _navigateWithRandomTransition(
                          context,
                          const CaseRequestListPage(),
                        );
                      },
                    ),
                    _buildAnimatedCaseCard(
                      context,
                      title: "My Requests",
                      icon: Icons.pending_actions,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFBF360C)], // Deep Orange
                      ),
                      onTap: () {
                        _navigateWithRandomTransition(
                          context,
                          const SeeMyCaseRequestsPage(),
                        );
                      },
                    ),
                    _buildAnimatedCaseCard(
                      context,
                      title: "My Cases",
                      icon: Icons.gavel,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A148C), Color(0xFF311B92)], // Deep Purple
                      ),
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId') ?? '';
                        if (userId.isNotEmpty) {
                          _navigateWithRandomTransition(
                            context,
                            MyCasesPage(userId: userId),
                          );
                        }
                      },
                    ),
                    _buildAnimatedCaseCard(
                      context,
                      title: "Cases to Fight",
                      icon: Icons.sports_mma, // Changed from Icons.fight to Icons.sports_mma
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC2185B), Color(0xFF880E4F)], // Pink/Purple
                      ),
                      onTap: () {
                        _navigateWithRandomTransition(
                          context,
                          const SeeMyRequestedCaseToFightListPage(),
                        );
                      },
                    ),
                    _buildAnimatedCaseCard(
                      context,
                      title: "All Cases",
                      icon: Icons.cases,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00838F), Color(0xFF004D40)], // Teal
                      ),
                      onTap: () async {
                        _navigateWithRandomTransition(
                          context,
                          const SeeAllCasesPage(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Recent Activity Card
              //_buildRecentActivityCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
            child: const Icon(Icons.gavel, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Case Management",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage your legal cases efficiently",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCaseCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Click",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.history,
              color: Colors.deepPurple.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recent Activity",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  "Your case updates will appear here",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.deepPurple.shade600,
            ),
          ),
        ],
      ),
    );
  }
}