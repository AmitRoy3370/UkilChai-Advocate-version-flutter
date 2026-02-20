import 'dart:convert';

import 'package:advocatechaiadvocate/AdvocatePages/AdvocateFilterPage.dart';
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
import 'Utils/BaseURL.dart' as BASE_URL;

void main() {
  runApp(LifecycleManager(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'উকিল',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'উকিল চাই'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

int index = 0;

Future<String?> getMyId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? myId = prefs.getString('userId');
  return myId;
}

Future<String?> getMyName() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? myId = prefs.getString('userId');
  String? token = prefs.getString('jwt_token');

  final response = await http.get(
    Uri.parse("${BASE_URL.Urls().baseURL}user/$myId"),
    headers: {
      'content-type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['name'];
  } else {
    return "";
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Widget> bottomPages = [];
  bool isLoading = true;
  int unreadCount = 0;

  String? myId, myName;

  final NotificationSocketService socketService = NotificationSocketService();

  @override
  void initState() {
    super.initState();
    initNotificationSocket();
    loadAllUser();

    //setUserActive(true);
  }

  @override
  void dispose() {
    //setUserActive(false);

    print("I am in main application dispose state....");

    super.dispose();
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

  Future<void> initNotificationSocket() async {
    String? id = await getMyId();

    if (id != null) {
      socketService.connect(id, (data) {
        showNotificationSnack(data["message"]);
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

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

  Future<void> loadAllUser() async {
    //myId = await getMyId();
    //myName = await getMyName();

    bottomPages = [
      Homepage(),
      PostFeedPage(),
      AdvocateFilterPage(),
      AllUserChatListScreen(currentUserId: myId, currentUserName: myName),
      LogIn(),
    ];

    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,

      appBar: AppBar(
        title: Text("উকিল"),
        centerTitle: true,
        backgroundColor: Colors.green,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
              child: ProfileImageWidget(),
            ),
          ),
        ],
      ),
      body: index == 3
          ? AllUserChatListScreen(currentUserId: myId, currentUserName: myName)
          : bottomPages[index],

      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: "Articles",
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Advocate",
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chat",
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: "LogIn",
            backgroundColor: Colors.black,
          ),
        ],
        currentIndex: index,
        onTap: (value) async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "clicked Index: $value and previous index : $index",
              ),
              duration: Duration(seconds: 2),
            ),
          );

          String? tempId;
          String? tempName;

          if (value == 3) {
            tempId = await getMyId();
            tempName = await getMyName();
          }

          setState(() {
            index = value;
            myId = tempId ?? myId;
            myName = tempName ?? myName;
          });
        },
      ),
    );
  }
}
