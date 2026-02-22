import 'package:advocatechaiadvocate/Auth/AuthService.dart';
import 'package:advocatechaiadvocate/CaseRelatedPages/see_my_requested_Case_to_fight.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../CaseRelatedPages/AddCaseRequestPage.dart';
import 'MyCasesPage.dart';
import 'SeeAllCases.dart';
import 'SeeMyCaseRequest.dart';
import 'case_request_list_page.dart';

class CaseHomePage extends StatelessWidget {
  const CaseHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Case"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _caseButton(
              context,
              title: "Add Case Request",
              icon: Icons.add_circle_outline,
              onTap: () {
                SharedPreferences.getInstance().then((prefs) {
                  String userId = prefs.getString('userId') ?? '';
                  print('User ID: $userId');

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddCaseRequestPage(userId: userId),
                    ),
                  );
                });

                /*Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddCaseRequestPage(userId: "LOGGED_IN_USER_ID"),
                  ),
                );*/
              },
            ),
            const SizedBox(height: 16),
            _caseButton(
              context,
              title: "See All Case Requests",
              icon: Icons.list_alt,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CaseRequestListPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            _caseButton(
              context,
              title: "See My Case Requests",
              icon: Icons.list_alt,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SeeMyCaseRequestsPage()),
                );
              },
            ),

            const SizedBox(height: 16),
            _caseButton(
              context,
              title: "See My Cases",
              icon: Icons.list_alt,
              onTap: () {
                SharedPreferences.getInstance().then((prefs) {
                  String userId = prefs.getString('userId') ?? '';
                  print('User ID: $userId');

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyCasesPage(userId: userId),
                    ),
                  );
                });

                /*Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyCasesPage(userId: "LOGGED_IN_USER_ID"),
                  ),
                );*/
              },
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),
            _caseButton(
              context,
              title: "See My Case Requests for fight",
              icon: Icons.list_alt,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeeMyRequestedCaseToFightListPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            _caseButton(
              context,
              title: "See All Cases",
              icon: Icons.list_alt,
              onTap: () {
                SharedPreferences.getInstance().then((prefs) {
                  String userId = prefs.getString('userId') ?? '';
                  print('User ID: $userId');

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SeeAllCasesPage()),
                  );
                });

                /*Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyCasesPage(userId: "LOGGED_IN_USER_ID"),
                  ),
                );*/
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _caseButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.blue),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
