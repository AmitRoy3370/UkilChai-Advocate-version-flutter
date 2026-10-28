import 'package:flutter/material.dart';
import '../Services/ReactionService.dart';
import '../Services/PostService.dart';
import '../PostRelatedPages/post_response.dart';
import '../PostRelatedPages/post_reaction.dart';

class PostIntegrationTestPage extends StatefulWidget {
  final String token;
  final String userId;
  final String postId;
  final String advocateId;

  const PostIntegrationTestPage({
    super.key,
    required this.token,
    required this.userId,
    required this.postId,
    required this.advocateId,
  });

  @override
  State<PostIntegrationTestPage> createState() => _PostIntegrationTestPageState();
}

class _PostIntegrationTestPageState extends State<PostIntegrationTestPage> {
  List<PostResponse> _posts = [];
  String _log = "Ready";

  Future<void> _runAllTests() async {
    try {
      // 1. Fetch all posts
      final all = await PostService.fetchAllPosts(widget.token);
      setState(() => _posts = all);
      _log += "\n✅ fetchAllPosts: ${all.length}";

      // 2. Add reaction
      final added = await ReactionService.addReaction(
        widget.postId,
        widget.userId,
        PostReactions.like.value,
        widget.token,
        "Nice post!",
      );
      _log += "\n✅ addReaction id: ${added?.id}";

      // 3. Update reaction
      if (added?.id != null) {
        await ReactionService.updateReaction(
          added!.id!,
          widget.postId,
          widget.userId,
          PostReactions.love.value,
          widget.token,
          "Changed to love",
        );
        _log += "\n✅ updateReaction";
      }

      // 4. Fetch by post
      final byPost =
          await ReactionService.fetchByPost(widget.postId, widget.token);
      _log += "\n✅ fetchByPost: ${byPost.length}";

      // 5. Fetch by user
      final byUser =
          await ReactionService.fetchByUser(widget.userId, widget.token);
      _log += "\n✅ fetchByUser: ${byUser.length}";

      // 6. Get by post + reaction
      final combo = await ReactionService.getByPostAndReaction(
          widget.postId, PostReactions.love.value, widget.token);
      _log += "\n✅ getByPostAndReaction: ${combo.length}";

      // 7. Search by comment
      final search =
          await ReactionService.searchByComment("love", widget.token);
      _log += "\n✅ searchByComment: ${search.length}";

      // 8. Get all reactions
      final allReact = await ReactionService.getAll(widget.token);
      _log += "\n✅ getAll reactions: ${allReact.length}";

      // 9. Delete reaction
      if (added?.id != null) {
        await ReactionService.deleteReaction(
            added!.id!, widget.userId, widget.token);
        _log += "\n✅ deleteReaction";
      }

      setState(() {});
    } catch (e) {
      setState(() => _log += "\n❌ ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Integration Test")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _runAllTests,
            child: const Text("Run All API Tests"),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_log),
              ),
            ),
          ),
        ],
      ),
    );
  }
}