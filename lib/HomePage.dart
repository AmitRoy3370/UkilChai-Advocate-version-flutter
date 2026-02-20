import 'package:advocatechaiadvocate/HomePage/AdvocateList.dart';

import 'package:advocatechaiadvocate/HomePage/QuickConnect.dart';
import 'package:advocatechaiadvocate/PostRelatedPages/post_feed_page_home_page.dart';
import 'package:flutter/material.dart';

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
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          SearchScreen(),
          const SizedBox(height: 20),

          QuickConnect(),

          const SizedBox(height: 20),

          /// 🔹 CASE OPTION
          /*Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CaseHomePage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.gavel, size: 28, color: Colors.blue),
                    SizedBox(width: 12),
                    Text(
                      "Case",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),*/
          PostFeedPageHomePage(),
          const SizedBox(height: 20),
          AdvocateList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
