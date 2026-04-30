import 'package:advocatechaiadvocate/PostRelatedPages/post_response.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './AdvocatePost.dart';
import './PostService.dart';
import './post_card.dart';
import 'CreateOrUpdatePostPage.dart';

class PostFeedPage extends StatefulWidget {
  const PostFeedPage({super.key});

  @override
  State<PostFeedPage> createState() => _PostFeedPageState();
}

class _PostFeedPageState extends State<PostFeedPage> {
  String? advocateId;

  // ✅ FutureBuilder ব্যবহারের জন্য Future তৈরি করুন
  Future<List<PostResponse>> getPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    advocateId = prefs.getString('advocateId') ?? '';

    final data = await PostService.fetchAllPosts(token);
    // রিভার্স অর্ডার করুন (নতুন পোস্ট আগে দেখাবে)
    return data.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Advocate Posts")),
      body: FutureBuilder<List<PostResponse>>(
        future: getPosts(),
        builder: (context, snapshot) {
          // লোডিং স্টেট
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error স্টেট
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Rebuild করে আবার FutureBuilder কল হবে
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          // Data স্টেট
          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No posts available'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (_, index) {
              final post = posts[index];
              final isOwner = post.advocateId == advocateId;

              return PostCard(
                post: post,
                onEdit: isOwner ? () => _editPost(post, index) : null,
                onDelete: isOwner ? () => _deletePost(post, index) : null,
                // ✅ onReactionChanged - PostCard এ callback পাঠান
                onReactionChanged: (reaction, action) {
                  // Reaction update handle করার জন্য
                  // PostFeedPage এ state update প্রয়োজন নেই,
                  // কারণ PostCard ই নিজের reactions update করবে
                  // কিন্তু如果需要 refresh posts, তাহলে:
                  _refreshPostAtIndex(index);
                },
                canReact: true,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ✅ PostCard এ reactions update হলে সেই specific post টি refresh করার method
  Future<void> _refreshPostAtIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final allPosts = await PostService.fetchAllPosts(token);
    final updatedPosts = allPosts.reversed.toList();

    if (index < updatedPosts.length) {
      setState(() {
        // পুরো লিস্ট না রিলোড করে শুধু specific post টি আপডেট করুন
        // কিন্তু FutureBuilder পুরো thing re-run করবে anyway
      });
    }
  }

  Future<void> _editPost(PostResponse post, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateOrUpdatePostPage(post: post, refresh: () {
        setState(() {});
      },)),
    );
    if (result == true) {
      setState(() {}); // FutureBuilder re-run করবে
    }
  }

  Future<void> _deletePost(PostResponse post, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final userId = prefs.getString('userId') ?? '';

    final response = await PostService.deletePost(post.id, userId, token);

    if (response == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post deleted successfully")),
      );
      setState(() {}); // FutureBuilder re-run করবে
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete post")),
      );
    }
  }

  Future<void> _createPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateOrUpdatePostPage(refresh: () {
      setState(() {});
      },)),
    );
    if (result == true) {
      setState(() {}); // FutureBuilder re-run করবে
    }
  }
}