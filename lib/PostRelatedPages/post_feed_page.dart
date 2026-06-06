import 'package:advocatechaiadvocate/PostRelatedPages/post_response.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './AdvocatePost.dart';
import './PostService.dart';
import './post_card.dart';
import 'CreateOrUpdatePostPage.dart';
import '../main.dart'; // Import for homePageKey

class PostFeedPage extends StatefulWidget {
  const PostFeedPage({super.key});

  @override
  State<PostFeedPage> createState() => _PostFeedPageState();
}

class _PostFeedPageState extends State<PostFeedPage> {
  String? advocateId;

  Future<List<PostResponse>> getPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    advocateId = prefs.getString('advocateId') ?? '';

    final data = await PostService.fetchAllPosts(token);
    return data.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to home page on back press
        _navigateToHomePage();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            "Advocate Posts",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
            onPressed: () {
              // Navigate to home page on back button press
              _navigateToHomePage();
            },
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: Colors.green,
          child: FutureBuilder<List<PostResponse>>(
            future: getPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 16),
                      Text('Loading posts...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.inter(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              }

              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No posts available',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createPost,
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (_, index) {
                  final post = posts[index];
                  final isOwner = post.advocateId == advocateId;

                  return PostCard(
                    post: post,
                    onEdit: isOwner ? () => _editPost(post, index) : null,
                    onDelete: isOwner ? () => _deletePost(post, index) : null,
                    onReactionChanged: (reaction, action) {
                      setState(() {});
                    },
                    canReact: true,
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createPost,
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _navigateToHomePage() {
    // Use pushAndRemoveUntil to clear the navigation stack and go to home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'উকিল চাই')),
      (route) => false,
    );
  }

  Future<void> _refreshPostAtIndex(int index) async {
    setState(() {});
  }

  Future<void> _editPost(PostResponse post, int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateOrUpdatePostPage(post: post, refresh: () {
        setState(() {});
      },)),
    );
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _deletePost(PostResponse post, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final userId = prefs.getString('userId') ?? '';

    final response = await PostService.deletePost(post.id, userId, token);

    if (response == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post deleted successfully"), backgroundColor: Colors.green),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete post"), backgroundColor: Colors.red),
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
      setState(() {});
    }
  }
}