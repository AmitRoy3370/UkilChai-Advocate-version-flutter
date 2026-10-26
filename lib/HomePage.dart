// lib/HomePage/home_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'HomePage/latest_questions_widget.dart';
import 'Utils/BaseURL.dart' as BASE_URL;
import 'LifeCycles/PresenceSocketService.dart';
import 'NotificationPages/notification_socket_service.dart';
import '../Auth/AuthService.dart';
import '../Auth/AuthGate.dart';
import '../LogInPage/LogIn.dart';
import 'HomePage/AdvocateList.dart';
import 'HomePage/QuickConnect.dart';
import 'HomePage/SearchScreen.dart';
import 'HomePage/latest_cases_widget.dart';
import '../PostRelatedPages/post_feed_page_home_page.dart';
import '../PostRelatedPages/post_feed_page.dart';
import '../AdvocatePages/advocate_home_page_pageview.dart';
import '../CaseRelatedPages/CaseHomePage.dart';
import '../CaseRelatedPages/hearing_calendar_page.dart';
import 'HomePage/corporate_banner.dart';
import '../Farayez/farayez_calculator.dart';
import 'HomePage/today_hearings_card.dart';

// ✅ Global RouteObserver so the homepage knows when it becomes visible again
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<Homepage>
    with WidgetsBindingObserver, RouteAware {
  Timer? _heartbeatTimer;
  String? advocateId;

  // ========== WELCOME BANNER STATE ==========
  bool _isWelcomeBannerVisible = true, isQuestionSelected = false;

  // ✅ Trigger variable to force reload of child widgets
  int _refreshTrigger = 0;

  // --- THEME COLORS (Matching Calendar Page) ---
  final Color _bgColor = const Color(0xFF121413);
  final Color _textColor = const Color(0xFFE0E0E0);
  final Color _mutedColor = const Color(0xFF888888);
  final Color _accentColor = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    collectAdvocateId();
    heartbit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      _refreshTrigger++;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _refreshTrigger++;
      });
    }
  }

  void reloadData() {
    if (mounted) {
      setState(() {
        _refreshTrigger++;
      });
    }
  }

  Future<void> collectAdvocateId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = (prefs.getString('advocateId') ?? '').trim();
    if (!mounted) return;
    setState(() {
      advocateId = id;
    });
  }

  Future<void> heartbit() async {
    final userId = await AuthService.getUserId();
    if (userId != null && userId.isNotEmpty) {
      _startHeartbeat(userId);
    }
  }

  void _startHeartbeat(String userId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 20),
      (timer) async {
        try {
          final url = Uri.parse(
            "${BASE_URL.Urls().baseURL}user-active/heartbeat/$userId",
          );
          final token = await AuthService.getToken();
          final response = await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          if (response.statusCode != 200) {
            print("❌ Heartbeat failed: ${response.statusCode}");
          }
        } catch (e) {
          print("❌ Heartbeat error: $e");
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOGIN GATE HELPER
  // Returns true if logged in (or just logged in), false otherwise.
  // ═══════════════════════════════════════════════════════════════════════
  Future<bool> _ensureLoggedIn() async {
    final loggedIn = await AuthGate.isLoggedIn();
    if (loggedIn) return true;
    if (!mounted) return false;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LogIn()),
    );
    return result == true;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OPEN PAGE (with login gate)
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> _openWithLoginGate(Widget page) async {
    final ok = await _ensureLoggedIn();
    if (!ok || !mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() => _refreshTrigger++);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final isTablet = screenWidth > 600 && screenWidth <= 800;

    return Container(
      color: _bgColor,
      child: RefreshIndicator(
        color: _accentColor,
        backgroundColor: const Color(0xFF1E201F),
        onRefresh: () async {
          setState(() {
            _refreshTrigger++;
          });
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
                _buildWelcomeBanner(context, isDesktop, isTablet),

                const SizedBox(height: 24),

                // ⚠️ Today's Hearings card — must self-gate (see patch below)
                const TodayHearingsCard(),

                const SizedBox(height: 24),

                QuickConnect(
                  key: UniqueKey(),
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),
                const SizedBox(height: 32),

                // =====================================================
                // ================== LATEST CASES =====================
                // =====================================================
                _buildSectionHeader(
                  "Latest Cases",
                  Icons.gavel_rounded,
                  hideSeeAll: true,
                ),
                const SizedBox(height: 16),
                LatestCasesWidget(
                  key: ValueKey('cases_$_refreshTrigger'),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader(
                  "Latest Questions",
                  Icons.question_answer_rounded,
                  hideSeeAll: true,
                ),
                const SizedBox(height: 16),
                LatestQuestionsWidget(
                  key: ValueKey('questions_$_refreshTrigger'),
                ),
                const SizedBox(height: 16),
                const CorporateBanner(),
                const SizedBox(height: 20),
                const SizedBox(height: 24),
                const FarayezCalculator(),
                const SizedBox(height: 20),
                _buildAdvocatePromotionCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== WELCOME BANNER ==========
  Widget _buildWelcomeBanner(
      BuildContext context, bool isDesktop, bool isTablet) {
    if (!_isWelcomeBannerVisible) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isWelcomeBannerVisible = true;
                });
              },
              icon: Icon(
                Icons.expand_more,
                color: _accentColor,
                size: 20,
              ),
              label: Text(
                "Show Welcome Message",
                style: GoogleFonts.inter(
                  color: _accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1C3326),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(
                    color: Color(0xFF234234),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final double logoSize = isDesktop ? 64 : (isTablet ? 56 : 48);
    final double logoRingPadding = isDesktop ? 4 : 3;
    final double logoInnerPadding = isDesktop ? 6 : 5;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 24,
        vertical: isDesktop ? 32 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF132B20), Color(0xFF1E3A2B)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF234234), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: _accentColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                      border: Border.all(
                        color: _accentColor.withOpacity(0.5),
                        width: logoRingPadding,
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E201F), Color(0xFF132B20)],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(logoInnerPadding),
                      child: ClipOval(
                        child: Container(
                          color: const Color(0xFF1E201F),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.gavel_rounded,
                              color: Color(0xFF4CAF50),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Welcome to উকিল",
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 28 : (isTablet ? 24 : 20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Your trusted legal partner. Connect with expert advocates, get legal advice, and manage your cases efficiently.",
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 16 : 14,
                  color: const Color(0xFFA0B0A8),
                  height: 1.5,
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isWelcomeBannerVisible = false;
                });
              },
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    bool hideSeeAll = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1C3326), Color(0xFF234234)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor.withOpacity(0.3)),
          ),
          child: Icon(icon, color: _accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (!hideSeeAll)
          TextButton(
            onPressed: () async {
              if (title == 'Featured Advocates') {
                // Browsing advocates is public
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdvocateHomePage()),
                );
              } else if (title == 'Recent Legal Updates') {
                // Feed browsing is public too
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostFeedPage()),
                );
              }
              if (mounted) setState(() => _refreshTrigger++);
            },
            child: Text(
              "See All",
              style: GoogleFonts.inter(
                color: _accentColor,
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3E1F5C), Color(0xFF2B1540)],
        ),
        border: Border.all(color: const Color(0xFF5D3A7A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.15),
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
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Gate external navigation behind login.
                    final ok = await _ensureLoggedIn();
                    if (!ok || !mounted) return;
                    final uri = Uri.parse('https://ukil.com.bd');
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("Visit User App"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2B754),
                    foregroundColor: Colors.black,
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