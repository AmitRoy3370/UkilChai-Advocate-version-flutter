import 'dart:convert';

import 'package:flutter/material.dart';
import '../Auth/AuthService.dart';
import '../LogInPage/LogIn.dart';
import 'ProfileImageWidget.dart';
import 'SeeMyProfile.dart';
import 'UpdateProfile.dart';
import '../Utils/BaseURL.dart' as BASEURL;
import 'package:http/http.dart' as http;

class ProfileMenuPage extends StatelessWidget {
  const ProfileMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Account"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: ProfileImageWidget(radius: 45)),

          const SizedBox(height: 20),

          profileTile(
            icon: Icons.person,
            title: "My Profile",
            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeeMyProfile()),
              );

            },
          ),

          profileTile(
            icon: Icons.edit,
            title: "Update Profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateProfile()),
              );
            },
          ),

          profileTile(
            icon: Icons.logout,
            title: "Logout",
            color: Colors.orange,
            onTap: () async {

              await AuthService.logout();

              Navigator.pop(context);

              /*Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogIn())
              );*/
            },
          ),

          profileTile(
            icon: Icons.delete,
            title: "Delete Account",
            color: Colors.red,
            onTap: () {
              showDeleteDialog(context);
            },
          ),
        ],
      ),
    );
  }

  static void deleteAccount(BuildContext context) async {
    String token = "";
    String userId = "";

    await AuthService.getToken().then((value) {
      token = value!;
    });

    await AuthService.getUserId().then((value) {
      userId = value!;
    });

    var url = Uri.parse("${BASEURL.Urls().baseURL}user/delete/$userId");

    var response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      print("Account deleted successfully");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.body)));

      AuthService.logout();
    } else {
      print("Account deletion failed");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.body)));
    }
  }

  static Widget profileTile({
    required IconData icon,
    required String title,
    Color color = Colors.black,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white70,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        onTap: onTap,
      ),
    );
  }

  static void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("This action is permanent. Are you sure?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              deleteAccount(context);

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
