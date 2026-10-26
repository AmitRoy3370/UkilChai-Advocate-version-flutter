import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/AuthGate.dart';
import '../LogInPage/LogIn.dart';
import '../CaseRelatedPages/case_tracking_model.dart';
import '../CaseRelatedPages/case_tracking_service.dart';
import '../CaseRelatedPages/hearing_calendar_page.dart';

class TodayHearingsCard extends StatefulWidget {
  const TodayHearingsCard({super.key});

  @override
  State<TodayHearingsCard> createState() => _TodayHearingsCardState();
}

class _TodayHearingsCardState extends State<TodayHearingsCard> {
  bool _isLoading = true;
  int _todayHearingsCount = 0;
  List<CaseTrackingStage> _allMyTrackings = [];

  // Colors matching your dark UI theme
  final Color _cardBgColor = const Color(0xFF132B20); // Deep green
  final Color _borderColor = const Color(0xFFE2B754); // Orange/Yellow left border
  final Color _iconBgColor = const Color(0xFF234234); // Lighter green for icon box

  @override
  void initState() {
    super.initState();
    _loadHearingsData();
  }

  Future<void> _loadHearingsData() async {
    // Skip the network call entirely if the user isn't logged in.
    final loggedIn = await AuthGate.isLoggedIn();
    if (!loggedIn) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _todayHearingsCount = 0;
          _allMyTrackings = [];
        });
      }
      return;
    }

    try {
      // 1. Fetch only my cases
      final trackings = await CaseTrackingService.findMyCases();

      // 2. Count how many are happening TODAY
      int todayCount = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var t in trackings) {
        if (t.trackingTime != null) {
          final dt = DateTime.tryParse(t.trackingTime!);
          if (dt != null) {
            final tDate = DateTime(dt.year, dt.month, dt.day);
            if (tDate.isAtSameMomentAs(today)) {
              todayCount++;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _allMyTrackings = trackings;
          _todayHearingsCount = todayCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Error loading today's hearings: $e");
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOGIN GATE + NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _openCalendar() async {
    // 1. Ensure logged in (retries after successful login)
    final loggedIn = await AuthGate.isLoggedIn();
    if (!loggedIn) {
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LogIn()),
      );
      if (result != true || !mounted) return;
      // After successful login, refresh the count so the card shows fresh data
      await _loadHearingsData();
    }

    // 2. Re-check token now that we're (maybe) logged in
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    if (token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please log in to view your hearings"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 3. Push the calendar page
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HearingCalendarPage(
          trackings: _allMyTrackings,
          token: token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle above the card
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              "Manage your practice",
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7C74),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Main Clickable Card
          GestureDetector(
            onTap: _openCalendar,
            child: Container(
              decoration: BoxDecoration(
                color: _cardBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: _borderColor,
                    width: 4.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Box
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _iconBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "📅",
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Hearings",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_isLoading)
                          Text(
                            "Loading...",
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA0B0A8),
                              fontSize: 13,
                            ),
                          )
                        else
                          Text(
                            "$_todayHearingsCount hearings scheduled",
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA0B0A8),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}