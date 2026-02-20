import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './AdvocatePost.dart';
import 'PostAttachmentViewer.dart';
import 'reaction_bar.dart';

class PostCardHomePage extends StatelessWidget {
  final AdvocatePost post;

  const PostCardHomePage({super.key, required this.post});

  // ---------------- GET USER NAME ----------------
  Future<String> getNameFromUser(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final url = "${BASE_URL.Urls().baseURL}user/search?userId=$userId";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body["name"] ?? "";
    }
    return "";
  }

  // ---------------- GET ADVOCATE NAME ----------------
  Future<String> getNameFromAdvocate(String advocateId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final url = "${BASE_URL.Urls().baseURL}advocate/$advocateId";

    //print("token from name of advocate :- $token");

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      //print("find advocate ${advocateId} from name from advocate....");

      final body = jsonDecode(response.body);
      final userId = body["userId"];

      //print("userId :- ${userId}");

      return getNameFromUser(userId);
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: getNameFromAdvocate(post.advocateId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading...");
                }
                if (!snapshot.hasData || snapshot.hasError) {
                  return const SizedBox.shrink();
                }
                return Text(snapshot.data!);
              },
            ),
            const SizedBox(height: 6),
            Text(
              post.postType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(post.postContent),
            const Divider(),
            if (post.attachmentId != null)
              ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  final token = prefs.getString('jwt_token') ?? '';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostAttachmentView(
                        attachmentId: post.attachmentId!,
                        jwtToken: token,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.attachment),
                    const SizedBox(width: 8),
                    Text("View Attachment"),
                  ],
                ),
              ),
            
          ],
        ),
      ),
    );
  }
}
