import 'package:advocatechaiadvocate/PostRelatedPages/post_card_home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './AdvocatePost.dart';
import './PostService.dart';
import './post_card.dart';

class PostFeedPageHomePage extends StatefulWidget {
  const PostFeedPageHomePage({super.key});

  @override
  State<PostFeedPageHomePage> createState() => _PostFeedPageHomePageState();
}

class _PostFeedPageHomePageState extends State<PostFeedPageHomePage> {
  bool loading = true;
  List<AdvocatePost> posts = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: 360,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true, // 👈 VERY IMPORTANT for web
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 300,
                child: PostCardHomePage(post: posts[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}
