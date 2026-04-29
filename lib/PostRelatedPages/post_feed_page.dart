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
  bool loading = true;
  List<PostResponse> posts = [];
  String? advocateId;

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    advocateId = prefs.getString('advocateId') ?? '';
    final userId = prefs.getString('userId') ?? '';

    final data = await PostService.fetchAllPosts(token);
    setState(() {
      posts = data;
      posts = posts.reversed.toList();
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
              itemBuilder: (_, i) {
                if (posts[i].advocateId == advocateId) {
                  return PostCard(
                    post: posts[i],
                    onEdit: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateOrUpdatePostPage(post: posts[i]),
                        ),
                      );
                    },
                    onDelete: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      final token = prefs.getString('jwt_token') ?? '';
                      final userId = prefs.getString('userId') ?? '';

                      int response = await PostService.deletePost(
                        posts[i].id,
                        userId,
                        token,
                      );

                      if (response == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Post deleted successfully"),
                          ),
                        );

                        setState(() {
                          posts.removeAt(i);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Failed to delete post"),
                          ),
                        );
                      }
                    },
                  );
                }

                return PostCard(post: posts[i]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateOrUpdatePostPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
