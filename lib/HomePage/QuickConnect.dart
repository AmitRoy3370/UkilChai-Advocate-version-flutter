import 'dart:convert';

import 'package:advocatechaiadvocate/ChatRelatedPages/CenterAdminChatListScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/AuthService.dart';
import '../CaseRelatedPages/CaseHomePage.dart';
import '../CaseRelatedPages/MyCasesPage.dart';
import '../QuestionPages/AskQuestionPage.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './QuickCard.dart';

import '../AdvocatePages/AdvocateFilterPage.dart';

class QuickConnect extends StatelessWidget {
  const QuickConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          children: const [
            Icon(Icons.rocket_launch, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              "Quick Connect",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // 2x2 Grid of Cards
        GridView.count(
          crossAxisCount: 2,                    // ← Fixed to 2 columns forever
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,               // nice proportion
          children: [
            // 1st Tile
            QuickCard(
              icon: Icons.person_search,
              title: "Find Expert",
              subtitle: "Connect with specialized advocates",
              onTap: () {
                print("Find Expert");

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdvocateFilterPage()),
                );
              },
            ),

            // 2nd Tile
            QuickCard(
              icon: Icons.chat_bubble_outline,
              title: "Free Consult",
              subtitle: "15-min free consultation",
              onTap: () async {
                print("Free Consult");

                SharedPreferences prefs = await SharedPreferences.getInstance();
                String userId = prefs.getString("userId") ?? "";
                String token = prefs.getString("jwt_token") ?? "";

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

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CenterAdminChatListScreen(
                        currentUserId: userId,
                        currentUserName: data['name'],
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'You need to log in first to fetch the data....',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            // 3rd Tile
            QuickCard(
              icon: Icons.help_outline_rounded,
              title: "Ask Question",
              subtitle: "Public Q&A with advocates",
              onTap: () async {
                print("Ask Question");

                SharedPreferences prefs = await SharedPreferences.getInstance();
                String userId = prefs.getString("userId") ?? "";

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AskQuestionPage(userId: userId),
                  ),
                );
              },
            ),

            // 4th Tile
            QuickCard(
              icon: Icons.calendar_month,
              title: "My Cases",
              subtitle: "Case Details",
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String userId = prefs.getString("userId") ?? "";

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaseHomePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
