import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './AdvocatePost.dart';
import './PostService.dart';
import './post_card.dart';

class PostFeedPage extends StatefulWidget {
  const PostFeedPage({super.key});

  @override
  State<PostFeedPage> createState() => _PostFeedPageState();
}

class _PostFeedPageState extends State<PostFeedPage> {
  bool loading = true;
  List<AdvocatePost> posts = [];

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final data = await PostService.fetchAllPosts(token);
    setState(() {
      posts = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Advocate Posts")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: posts.length,
        itemBuilder: (_, i) => PostCard(post: posts[i]),
      ),
    );
  }
}