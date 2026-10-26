import 'dart:convert';
import '../PostRelatedPages/post_reaction.dart';
import '../PostRelatedPages/post_reaction_response.dart';
import '../PostRelatedPages/post_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './ReactionService.dart';
import './PostReaction.dart';

class ReactionBar extends StatefulWidget {
  final PostResponse postResponse;
  final Function(PostReactionResponse reaction, String action)? onReactionChanged;
  final bool? canReact;

  const ReactionBar({
    super.key,
    required this.postResponse,
    this.onReactionChanged,
    this.canReact,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  final TextEditingController _commentController = TextEditingController();
  String? selectedReaction;
  bool submitting = false;
  List<PostReactionResponse> reactions = [];
  String? myUserId, myName, myFullName;

  final Map<String, IconData> reactionIcons = {
    "LIKE": Icons.thumb_up,
    "LOVE": Icons.favorite,
    "WOW": Icons.sentiment_very_satisfied,
    "SAD": Icons.sentiment_dissatisfied,
    "ANGRY": Icons.sentiment_very_dissatisfied,
    "HAHA": Icons.mood,
    "CARE": Icons.healing,
  };

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReactions() async {
    final prefs = await SharedPreferences.getInstance();
    myUserId ??= prefs.getString('userId');
    myName = await getNameFromUser(myUserId!);
    
    setState(() {
      reactions = widget.postResponse.reactions;
    });
  }

  Future<String> getNameFromUser(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final url = "${BASE_URL.Urls().baseURL}user/search?userId=$userId";
    final response = await http.get(
      Uri.parse(url),
      headers: {"content-type": "application/json", "Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      setState(() {
         myFullName = body["fullName"];
      });

      return body["name"] ?? "User";
    }
    return "User";
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> reactionCounts = {};
    for (var r in reactions.where((r) => r.postReaction?.value != null)) {
      reactionCounts[r.postReaction!.value] = (reactionCounts[r.postReaction?.value] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reaction Summary Chips
        if (reactionCounts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: reactionCounts.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(reactionIcons[entry.key] ?? Icons.help_outline, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        entry.value.toString(),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        // Reactions and Comments List
        if (reactions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reactions.length,
              itemBuilder: (context, index) {
                var r = reactions[index];
                final userName = r.fullName ?? r.userName;
                final isOwn = r.userId == myUserId;
                final hasReaction = r.postReaction != null;
                final reactionValue = hasReaction ? r.postReaction!.value : '';
                final hasContent = hasReaction || (r.comment != null && r.comment!.isNotEmpty);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : "?",
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            if (hasContent) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (hasReaction && reactionValue.isNotEmpty)
                                    Icon(reactionIcons[reactionValue] ?? Icons.help_outline, size: 14),
                                  if (r.comment != null && r.comment!.isNotEmpty) ...[
                                    if (hasReaction) const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        r.comment!,
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isOwn && widget.canReact == true)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[500]),
                          onSelected: (value) {
                            if (value == 'Edit') {
                              _editReaction(r);
                            } else if (value == 'Delete') {
                              _deleteReaction(r.id!, r);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'Edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'Delete', child: Text('Delete')),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

        // New Reaction Input
        if (widget.canReact == true) ...[
          // Reaction Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: reactionIcons.keys.map((reaction) => _reactionBtn(reaction)).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Comment Input
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _commentController,
              minLines: 1,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Write a comment (optional)",
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, size: 18),
              label: Text(submitting ? "Submitting..." : "Submit"),
              onPressed: submitting ? null : _submitNew,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _reactionBtn(String reaction) {
    final isSelected = selectedReaction == reaction;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        avatar: Icon(reactionIcons[reaction] ?? Icons.help_outline, size: 16),
        label: const SizedBox.shrink(),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            selectedReaction = isSelected ? null : reaction;
          });
        },
        padding: const EdgeInsets.all(8),
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.purple.withOpacity(0.2),
        checkmarkColor: Colors.purple,
      ),
    );
  }

  Future<void> _submitNew() async {
    final comment = _commentController.text.trim();
    if (selectedReaction == null && comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please add a reaction or write a comment"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => submitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final userId = prefs.getString('userId') ?? '';

    try {
      PostReaction? reaction = await ReactionService.addReaction(
        widget.postResponse.id,
        userId,
        selectedReaction,
        token,
        comment.isEmpty ? null : comment,
      );

      if (reaction != null) {
        final reactionResponse = PostReactionResponse(
          id: reaction.id,
          postReaction: reaction.reaction != null ? PostReactions.fromString(reaction.reaction!) : null,
          comment: reaction.comment,
          userId: reaction.userId,
          userName: myName!,
          fullName: myFullName,
          advocatePostId: reaction.advocatePostId,
        );

        widget.onReactionChanged?.call(reactionResponse, "add");
        
        setState(() {
          reactions.insert(0, reactionResponse);
        });
        
        _commentController.clear();
        selectedReaction = null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submitted successfully"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => submitting = false);
    }
  }

  Future<void> _editReaction(PostReactionResponse r) async {
    String? editReaction = r.postReaction!.value;
    final editCommentController = TextEditingController(text: r.comment ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Edit Reaction", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: reactionIcons.keys.map((reaction) {
                        final isSelected = editReaction == reaction;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            avatar: Icon(reactionIcons[reaction] ?? Icons.help_outline, size: 16),
                            label: const SizedBox.shrink(),
                            selected: isSelected,
                            onSelected: (_) {
                              setDialogState(() {
                                editReaction = isSelected ? null : reaction;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editCommentController,
                    minLines: 2,
                    maxLines: 4,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Edit comment",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final comment = editCommentController.text.trim();
      if (editReaction == null && comment.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please add a reaction or write a comment"), backgroundColor: Colors.orange),
        );
        editCommentController.dispose();
        return;
      }

      setState(() => submitting = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      try {
        PostReaction? postReaction = await ReactionService.updateReaction(
          r.id,
          widget.postResponse.id,
          myUserId!,
          editReaction,
          token,
          comment.isEmpty ? null : comment,
        );

        if (postReaction != null) {
          final updatedResponse = r.copyWith(
            postReaction: PostReactions.fromString(postReaction.reaction!),
            comment: postReaction.comment,
          );
          
          widget.onReactionChanged?.call(updatedResponse, "update");
          
          setState(() {
            final index = reactions.indexWhere((item) => item.id == r.id);
            if (index != -1) {
              reactions[index] = updatedResponse;
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Updated successfully"), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Update failed"), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => submitting = false);
      }
    }
    editCommentController.dispose();
  }

  Future<void> _deleteReaction(String reactionId, PostReactionResponse postReactionResponse) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Delete Reaction", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => submitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    try {
      bool deleted = await ReactionService.deleteReaction(reactionId, myUserId!, token);
      if (deleted) {
        widget.onReactionChanged?.call(postReactionResponse, "remove");
        setState(() {
          reactions.removeWhere((item) => item.id == reactionId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Deleted successfully"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => submitting = false);
    }
  }
}