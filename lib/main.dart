import 'dart:convert';
import 'package:advocatechaiadvocate/AdvocatePages/advocate_home_page_pageview.dart';
import 'package:advocatechaiadvocate/PostRelatedPages/post_feed_page.dart';
import 'package:advocatechaiadvocate/ProfilePage/ProfileAvatar.dart';
import 'package:advocatechaiadvocate/ProfilePage/ProfileImageWidget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ChatRelatedPages/AllUserChatListScreen.dart';
import 'ChatRelatedPages/user_active_service.dart';
import 'HomePage.dart';
import 'LifeCycles/LifecycleManager.dart';
import 'LogInPage/LogIn.dart';
import 'NotificationPages/notification_page.dart';
import 'NotificationPages/notification_socket_service.dart';
import 'PostRelatedPages/post_feed_page_home_page.dart';
import 'ProfilePage/ProfileMenuPage.dart';
import 'TermsAndPrivacyScreen.dart';
import 'AboutUkilScreen.dart';
import 'Utils/BaseURL.dart' as BASE_URL;
import 'PageTransition.dart';

// Global key to access MyHomePage state from anywhere
final GlobalKey<_MyHomePageState> homePageKey = GlobalKey<_MyHomePageState>();

void main() {
  runApp(
    LifecycleManager(child: MyApp()),
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

  const MyHomePage({super.key, required this.title, this.userId, this.userName});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Widget> bottomPages = [];
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  String? _userId;
  String? _userName;
  int unreadCount = 0;

  final NotificationSocketService socketService = NotificationSocketService();

  // Public method to refresh user data - can be called from anywhere
  Future<void> refreshUserData() async {
    print("Refreshing user data...");
    await _loadUserData();
    print("Loaded userId: $_userId");
    print("Loaded userName: $_userName");

    setState(() {
      bottomPages = [
        Homepage(),
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

    _initializeData();
  }

  @override
  void dispose() {
    print("I am in main application dispose state....");
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await _initializeNotification();

    setState(() {
      bottomPages = [
        Homepage(),
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
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('jwt_token');

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
          setState(() {
            _userId = userId;
            _userName = data['name'] ?? "User";
          });
          print('User loaded: $_userName');
        }
      } catch (e) {
        print('Error loading user: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Don't find any user Info....")),
      );

      setState(() {
        _userId = null;
        _userName = null;
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

      if (response.statusCode == 200) {
        setState(() {
          unreadCount = jsonDecode(response.body).length;
        });
      }
    }
  }

  void showNotificationSnack(String message) {
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
          print("response body in user main service :- $body");
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
          /// 🔔 Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  setState(() {
                    unreadCount = 0; // reset when opened
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationPage()),
                  );
                },
              ),
              /// 🔴 Badge Counter
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
          /// 👤 Profile Image
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileMenuPage()),
                );
              },
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
                    const Divider(color: Colors.white38, height: 20, thickness: 1),
                    
                    // About Ukil Option
                    _buildModernDrawerItem(
                      icon: Icons.info_outline,
                      title: "About Ukil",
                      index: 5,
                    ),
                    
                    // Terms & Privacy Option
                    _buildModernDrawerItem(
                      icon: Icons.description,
                      title: "Terms & Privacy",
                      index: 6,
                    ),
                    
                    const Divider(color: Colors.white38, height: 20, thickness: 1),
                    
                    _buildModernDrawerItem(
                      icon: _userId != null ? Icons.person : Icons.login,
                      title: _userId != null ? "Profile" : "LogIn",
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
          ? const Center(child: CircularProgressIndicator())
          : (_selectedIndex == 3 && _userId != null)
              ? AllUserChatListScreen(currentUserId: _userId, currentUserName: _userName)
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
    // For About and Terms pages (indices 5 and 6), never show as selected
    final isSelected = (index == 5 || index == 6) ? false : (_selectedIndex == index);

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
            ? const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)
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
              Icon(Icons.circle, color: Colors.white.withOpacity(0.5), size: 8),
              const SizedBox(width: 4),
              Icon(Icons.circle, color: Colors.white.withOpacity(0.5), size: 8),
              const SizedBox(width: 4),
              Icon(Icons.circle, color: Colors.white.withOpacity(0.5), size: 8),
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
    // Handle About Ukil (index 5) - Open as new page
    if (newIndex == 5) {
      Navigator.pop(context); // Close drawer
      await NavigationHelper.push(
        context,
        const AboutUkilScreen(),
        transitionType: await AnimatedRoute.getRandomSafeAnimation(),
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    // Handle Terms & Privacy (index 6) - Open as new page
    if (newIndex == 6) {
      Navigator.pop(context); // Close drawer
      await NavigationHelper.push(
        context,
        const TermsAndPrivacyScreen(),
        transitionType: await AnimatedRoute.getRandomSafeAnimation(),
        duration: const Duration(milliseconds: 500),
      );
      return;
    }

    // Handle Login/Profile (index 4)
    if (newIndex == 4) {
      Navigator.pop(context); // Close drawer

      if (_userId != null && _userId!.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileMenuPage()),
        );
        await refreshUserData();
        await _loadUnreadCount();
      } else {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LogIn(),
          ),
        );

        if (result == true && mounted) {
          // wait a little for SharedPreferences to settle
          await Future.delayed(const Duration(milliseconds: 300));
          await refreshUserData();
          await _loadUnreadCount();
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Welcome! You have successfully logged in."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      return;
    }

    // For main tab navigation (indices 0, 1, 2, 3)
    if (newIndex >= 0 && newIndex < bottomPages.length) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }
    
    Navigator.pop(context);
  }
}