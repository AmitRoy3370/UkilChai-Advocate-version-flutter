import 'dart:convert';

import 'package:advocatechaiadvocate/PostRelatedPages/post_response.dart';
import 'package:advocatechaiadvocate/Utils/AdvocateSpeciality.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './AdvocatePost.dart';
import 'PostAttachmentViewer.dart';
import 'reaction_bar.dart';

class PostCardHomePage extends StatelessWidget {
  final PostResponse post;

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

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "content-type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final userId = body["userId"];
      return getNameFromUser(userId);
    }
    return "";
  }

  /// Returns true only when the post has a non-empty title.
  bool get _hasTitle =>
      post.postTitle != null && post.postTitle!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- ADVOCATE NAME ----------
              Text(
                post.advocateName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),

              // ---------- POST TITLE (conditional) ----------
              if (_hasTitle) ...[
                Text(
                  post.postTitle!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // ---------- POST TYPE ----------
              Text(
                post.postType.apiValue,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              // ---------- POST CONTENT ----------
              Text(post.postContent),

              const Divider(),

              // ---------- ATTACHMENT ----------
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
                    children: const [
                      Icon(Icons.attachment),
                      SizedBox(width: 8),
                      Text("View Attachment"),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}