import 'dart:convert';
import '../AdvocatePages/advocate_home_page_pageview.dart';
import '../PostRelatedPages/post_feed_page.dart';
import '../ProfilePage/ProfileAvatar.dart';
import '../ProfilePage/ProfileImageWidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../Auth/AuthService.dart';
import 'ChatRelatedPages/AllUserChatListScreen.dart';
import 'ChatRelatedPages/user_active_service.dart';
import 'HomePage.dart'; // Note: You might want to rename this file if it's the main scaffold
import 'LifeCycles/LifecycleManager.dart';
import 'LifeCycles/PresenceSocketService.dart';
import 'LogInPage/LogIn.dart';
import 'NotificationPages/notification_page.dart';
import 'NotificationPages/notification_socket_service.dart';
import 'NotificationPages/notification_service.dart';
import 'package:provider/provider.dart';
import 'PostRelatedPages/post_feed_page_home_page.dart';
import 'ProfilePage/ProfileMenuPage.dart';
import 'TermsAndPrivacyScreen.dart';
import 'AboutUkilScreen.dart';
import 'Utils/BaseURL.dart' as BASE_URL;
import 'dart:async';
import 'PageTransition.dart';
import 'splash_screen.dart';

import '../Auth/AuthGate.dart';
import '../AdvocatePages/AdvocateProfilePage.dart';
import '../QuestionPages/AskQuestionPage.dart';
// 👇 ADDED IMPORT FOR LIVE LOCATION
import '../LiveLocations/live_location_screen.dart';
import 'package:provider/provider.dart';
import 'LiveLocations/live_location_provider.dart';

// 👇 ADD THESE IMPORTS
import '../DirectorsPages/director_profile_page.dart';
import '../ShareholderPages/shareholder_profile_page.dart';
import '../DirectorsPages/director_list_page.dart';
import '../ShareholderPages/shareholder_list_page.dart';
import '../CompanyPages/company_registration_screen.dart';
import '../CompanyPages/my_company_page.dart';
import '../GroupChat/GroupChatHome.dart';

// Global key to access MyHomePage state from anywhere
final GlobalKey<_MyHomePageState> homePageKey = GlobalKey<_MyHomePageState>();

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: LifecycleManager(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'উকিল',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      navigatorObservers: [routeObserver],
      home: MyHomePage(
        key: homePageKey,
        title: 'উকিল চাই',
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String? userId, userName;
  final String? directorId, shareHolderId;

  const MyHomePage({
    super.key,
    required this.title,
    this.userId,
    this.userName,
    this.directorId,
    this.shareHolderId,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Widget> bottomPages = [];
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<_MyHomePageState> homePageKey = GlobalKey<_MyHomePageState>();
  final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();
  int _selectedIndex = 0;
  Timer? _heartbeatTimer;
  String? _userId;
  String? _userName;

  // 👇 ADDED MISSING IDS
  String? _directorId;
  String? _shareHolderId;
  String? _advocateId; // 👈 Added to pass to Live Location

  // 👇 ADDED: advocate flag for drawer label + routing
  bool _isAdvocate = false;

  bool _isOnline = false;

  int unreadCount = 0;

  final NotificationSocketService socketService = NotificationSocketService();

  Future<void> refreshUserData() async {
    print("Refreshing user data...");
    await _loadUserData();
    print("Loaded userId: $_userId");
    print("Loaded userName: $_userName");

    if (!mounted) return;

    setState(() {
      bottomPages = [
        Homepage(key: homeScreenKey),
        PostFeedPage(),
        AdvocateHomePage(),
        AllUserChatListScreen(
          currentUserId: _userId,
          currentUserName: _userName,
        ),
        LogIn(),
      ];
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.userId != null) {
      setState(() {
        _userId = widget.userId;
      });
    }

    if (widget.userName != null) {
      setState(() {
        _userName = widget.userName;
      });
    }

    if (widget.directorId != null) {
      setState(() {
        _directorId = widget.directorId;
      });
    }

    if (widget.shareHolderId != null) {
      setState(() {
        _shareHolderId = widget.shareHolderId;
      });
    }

    _initializeData();
  }

  void _startPresence() {
    if (_userId != null && _userId!.isNotEmpty) {
      final socketService = PresenceSocketService();
      socketService.connect(_userId!);
      _startHeartbeat(_userId!);
      if (mounted) {
        setState(() {
          _isOnline = true;
        });
      }
      print('🟢 User is now ONLINE');
    }
  }

  void _startHeartbeat(String userId) {
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 20),
      (timer) async {
        try {
          final url = Uri.parse(
              "${BASE_URL.Urls().baseURL}user-active/heartbeat/$userId");
          final token = await AuthService.getToken();

          final response = await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            // Heartbeat successful
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
  void dispose() {
    print("I am in main application dispose state....");
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final splashStart = DateTime.now();

    await Future.wait([
      _loadUserData().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ _loadUserData timeout');
        },
      ),
      _initializeNotification().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ _initializeNotification timeout');
        },
      ),
    ]);

    final elapsed = DateTime.now().difference(splashStart);
    const minDuration = Duration(seconds: 2);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    if (!mounted) return;

    setState(() {
      bottomPages = [
        Homepage(key: homeScreenKey),
        PostFeedPage(),
        AdvocateHomePage(),
        AllUserChatListScreen(
          currentUserId: _userId,
          currentUserName: _userName,
        ),
        LogIn(),
      ];
      isLoading = false;
    });

    if (_userId != null && _userId!.isNotEmpty) {
      _startPresence();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('jwt_token');

    // 👇 FETCH DIRECTOR / SHAREHOLDER / ADVOCATE IDS
    final directorId = prefs.getString('directorId');
    final shareHolderId = prefs.getString('shareHolderId');
    final advocateId = (prefs.getString('advocateId') ?? '').trim();

    print('Loading user data - userId: $userId');

    if (userId != null && token != null && userId.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user/search?userId=$userId"),
          headers: {
            'content-type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (!mounted) return;
          setState(() {
            _userId = userId;
            _userName = data['name'] ?? "User";
            _directorId = directorId;
            _shareHolderId = shareHolderId;
            _advocateId = advocateId.isNotEmpty ? advocateId : null; // 👈 Stored
            _isAdvocate = advocateId.isNotEmpty;
          });
          print('User loaded: $_userName');
        }
      } catch (e) {
        print('Error loading user: $e');
      }
    } else {
      if (!mounted) return;
      setState(() {
        _userId = null;
        _userName = null;
        _isAdvocate = false;
        _directorId = null;
        _shareHolderId = null;
        _advocateId = null;
      });
    }
  }

  Future<void> _initializeNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final myId = prefs.getString('userId');

    if (myId != null && myId.isNotEmpty) {
      await initNotificationSocket();
    }
  }

  Future<void> initNotificationSocket() async {
    String? id = await getMyId();

    if (id != null) {
      socketService.connect(id, (data) {
        showNotificationSnack(data["message"]);
        _loadUnreadCount();
      });

      await _loadUnreadCount();
    }
  }

  Future<void> _loadUnreadCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    String? id = prefs.getString('userId');

    if (id != null && token != null) {
      final response = await http.get(
        Uri.parse("${BASE_URL.Urls().baseURL}notifications/unread/$id"),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          unreadCount = jsonDecode(response.body).length;
        });
      }
    }
  }

  void showNotificationSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<String?> getMyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? myId = prefs.getString('userId');
    return myId;
  }

  void setUserActive(bool active) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      String? userId = prefs.getString('userId');
      if (userId != null) {
        final response = await http.get(
          Uri.parse("${BASE_URL.Urls().baseURL}user-active/user/$userId"),
          headers: {
            'content-type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          await UserActiveService.updateUserActive(
            body["id"],
            userId,
            active,
            token,
          );
        } else {
          await UserActiveService.addUserActive(userId, active, token);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _openProfileTarget() async {
    final loggedIn = await AuthGate.isLoggedIn();
    if (!loggedIn) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LogIn()),
      );
      if (result == true && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        await refreshUserData();
        await _loadUnreadCount();
        setState(() {});
      }
      return;
    }

    final isAdv = await AuthGate.isAdvocate();
    if (!mounted) return;

    if (isAdv) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdvocateProfilePage()),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileMenuPage()),
      );
    }
    await refreshUserData();
    await _loadUnreadCount();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white70,
      appBar: AppBar(
        title: const Text("উকিল"),
        centerTitle: true,
        backgroundColor: Colors.green,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () async {
                  final loggedIn = await AuthGate.isLoggedIn();
                  if (!loggedIn) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LogIn()),
                    );
                    return;
                  }
                  if (!mounted) return;
                  setState(() {
                    unreadCount = 0;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationPage()),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: _openProfileTarget,
              child: ProfileImageWidget(
                key: ValueKey(_userId),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        width: 280,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade800,
                Colors.green.shade600,
                Colors.green.shade400,
              ],
            ),
          ),
          child: Column(
            children: [
              _buildModernDrawerHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildModernDrawerItem(
                      icon: Icons.home,
                      title: "Home",
                      index: 0,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.article,
                      title: "Post",
                      index: 1,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.person,
                      title: "Advocate",
                      index: 2,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.chat,
                      title: "Chat",
                      index: 3,
                    ),

                    // 👇 ADDED GROUP CHAT BUTTON HERE
                    _buildModernDrawerItem(
                      icon: Icons.group,
                      title: "Group Chat",
                      index: 16, // Using 16 as the new unique index
                    ),

                    // 👇 ADDED LIVE LOCATION BUTTON HERE
                    _buildModernDrawerItem(
                      icon: Icons.map,
                      title: "Live Location",
                      index: 15, 
                    ),

                    const Divider(
                        color: Colors.white38, height: 20, thickness: 1),

                    // 👇 DIRECTOR SECTION
                    if (_directorId != null && _directorId!.isNotEmpty)
                      _buildModernDrawerItem(
                        icon: Icons.person,
                        title: "Director Profile",
                        index: 6,
                      ),

                    const Divider(
                        color: Colors.white38, height: 20, thickness: 1),

                    // 👇 SHAREHOLDER SECTION
                    if (_shareHolderId != null && _shareHolderId!.isNotEmpty)
                      _buildModernDrawerItem(
                        icon: Icons.person,
                        title: "Shareholder Profile",
                        index: 9,
                      ),

                    const Divider(
                        color: Colors.white38, height: 20, thickness: 1),

                    // 👇 LIST VIEWS
                    _buildModernDrawerItem(
                      icon: Icons.people,
                      title: "All Directors",
                      index: 7,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.people_outline,
                      title: "All Shareholders",
                      index: 8,
                    ),

                    const Divider(
                        color: Colors.white38, height: 20, thickness: 1),

                    // 👇 COMPANY SECTION
                    _buildModernDrawerItem(
                      icon: Icons.business,
                      title: "Company Registration",
                      index: 13,
                    ),
                    _buildModernDrawerItem(
                      icon: Icons.business_center,
                      title: "My Companies",
                      index: 14,
                    ),
                    // 👇 ADDED ASK QUESTION BUTTON HERE
                    _buildModernDrawerItem(
                      icon: Icons.help_outline, // or Icons.question_answer
                      title: "Ask Question",
                      index: 17, 
                    ),

                    const Divider(
                        color: Colors.white38, height: 20, thickness: 1),

                    _buildModernDrawerItem(
                      icon: Icons.info_outline,
                      title: "About Ukil",
                      index: 5,
                    ),

                    _buildModernDrawerItem(
                      icon: Icons.description,
                      title: "Terms & Privacy",
                      index: 12,
                    ),

                    const Divider(
                        color: Colors.white38, height: 20, thickness: 1),

                    _buildModernDrawerItem(
                      icon: _userId != null ? Icons.person : Icons.login,
                      title: _userId != null
                          ? (_isAdvocate ? "Advocate Profile" : "Profile")
                          : "LogIn",
                      index: 4,
                    ),
                  ],
                ),
              ),
              _buildModernFooter(),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const SplashScreen()
          : (_selectedIndex == 3 && _userId != null)
              ? AllUserChatListScreen(
                  currentUserId: _userId, currentUserName: _userName)
              : bottomPages[_selectedIndex],
    );
  }

  Widget _buildModernDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        children: [
          Hero(
            tag: 'profileHero',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: _userId != null
                      ? ProfileAvatar(key: ValueKey(_userId))
                      : const Icon(Icons.person, size: 50, color: Colors.green),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName ?? "Invited Guest",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _userId != null ? "Online" : "Offline",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    // 👇 Handle special pages so they don't stay highlighted
    final isSpecialPage = (index == 6 ||
        index == 7 ||
        index == 8 ||
        index == 9 ||
        index == 11 ||
        index == 12 ||
        index == 13 ||
        index == 14 ||
        index == 15 ||
        index == 16 ||
        index == 17); // Added 15
    final isSelected = isSpecialPage ? false : (_selectedIndex == index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 16)
            : null,
        onTap: () {
          _onItemTapped(index);
        },
      ),
    );
  }

  Widget _buildModernFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle,
                  color: Colors.white.withOpacity(0.5), size: 8),
              const SizedBox(width: 4),
              Icon(Icons.circle,
                  color: Colors.white.withOpacity(0.5), size: 8),
              const SizedBox(width: 4),
              Icon(Icons.circle,
                  color: Colors.white.withOpacity(0.5), size: 8),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "© ${DateTime.now().year} উকিল চাই",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int newIndex) async {
    // ─── Auth gate ────────────────────────────────────────────────
    // Home (0), About Ukil (5), Terms & Privacy (12) are public.
    const publicIndexes = {0, 5, 12};
    if (!publicIndexes.contains(newIndex)) {
      final loggedIn = await AuthGate.isLoggedIn();
      if (!loggedIn) {
        Navigator.pop(context); // close drawer
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogIn()),
        );
        if (result == true && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          await refreshUserData();
          await _loadUnreadCount();
          setState(() {});
        }
        return;
      }
    }

    // 👇 HANDLE ASK QUESTION (index 17)
    if (newIndex == 17) {
      Navigator.pop(context);
      if (_userId == null || _userId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AskQuestionPage(
            userId: _userId!,
          ),
        ),
      );
      return;
    }



    // 👇 HANDLE GROUP CHAT (index 16)
    if (newIndex == 16) {
      Navigator.pop(context);
      if (_userId == null || _userId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatHome(
            currentUserId: _userId!,
            currentUserName: _userName ?? "User",
          ),
        ),
      );
      return;
    }



    // ───────────────────────────────────────────────────────────────
    // 👇 HANDLE LIVE LOCATION (index 15)
    if (newIndex == 15) {
      Navigator.pop(context);
      if (_userId == null || _userId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          // FIX: Wrap the screen with the required Provider
          builder: (context) => ChangeNotifierProvider(
            create: (_) => LiveLocationProvider(), // <--- This will now be recognized
            child: LiveLocationScreen(
              userId: _userId!,
              userName: _userName ?? "User",
              advocateId: _advocateId, // Passes null if not an advocate
            ),
          ),
        ),
      );
      return;
    }

    // Handle Company Registration (index 13)
    if (newIndex == 13) {
      Navigator.pop(context);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CompanyRegistrationScreen(userId: userId)),
      );
      return;
    }

    // Handle My Companies (index 14)
    if (newIndex == 14) {
      Navigator.pop(context);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyCompanyPage()),
      );
      return;
    }

    // Handle Director Profile (index 6)
    if (newIndex == 6) {
      Navigator.pop(context);
      final prefs = await SharedPreferences.getInstance();
      final storedDirectorId = prefs.getString('directorId');
      final directorIdToUse = _directorId ?? storedDirectorId;

      if (directorIdToUse != null && directorIdToUse.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DirectorProfilePage(
              userId: _userId ?? '',
              directorId: directorIdToUse,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You are not registered as a director. Please register first.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Handle All Directors (index 7)
    if (newIndex == 7) {
      Navigator.pop(context);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DirectorListPage()),
      );
      return;
    }

    // Handle All Shareholders (index 8)
    if (newIndex == 8) {
      Navigator.pop(context);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShareholderListPage()),
      );
      return;
    }

    // Handle Shareholder Profile (index 9)
    if (newIndex == 9) {
      Navigator.pop(context);
      final prefs = await SharedPreferences.getInstance();
      final storedShareHolderId = prefs.getString('shareHolderId');
      final shareHolderIdToUse = _shareHolderId ?? storedShareHolderId;

      if (shareHolderIdToUse != null && shareHolderIdToUse.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShareholderProfilePage(
              userId: _userId ?? '',
              shareholderId: shareHolderIdToUse,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You are not registered as a shareholder. Please register first.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // ─── Existing logic ──────────────────────────────────────────
    if (newIndex == 5) {
      Navigator.pop(context);
      await NavigationHelper.push(
        context,
        const AboutUkilScreen(),
        transitionType: await AnimatedRoute.getRandomSafeAnimation(),
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    if (newIndex == 0) {
      homeScreenKey.currentState?.reloadData();
    }

    if (newIndex == 12) {
      Navigator.pop(context);
      await NavigationHelper.push(
        context,
        const TermsAndPrivacyScreen(),
        transitionType: await AnimatedRoute.getRandomSafeAnimation(),
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    // Profile / Advocate Profile
    if (newIndex == 4) {
      Navigator.pop(context);
      await _openProfileTarget();
      return;
    }

    if (newIndex >= 0 && newIndex < bottomPages.length) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }

    Navigator.pop(context);
  }
}