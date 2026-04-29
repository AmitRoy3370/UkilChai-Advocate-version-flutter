import 'dart:convert';
import 'package:advocatechaiadvocate/PostRelatedPages/post_reaction_response.dart';
import 'package:advocatechaiadvocate/PostRelatedPages/post_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './ReactionService.dart';
import './PostReaction.dart';

class ReactionBar extends StatefulWidget {
  final PostResponse postResponse;
  const ReactionBar({super.key, required this.postResponse});
  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  final TextEditingController _commentController = TextEditingController();
  String? selectedReaction;
  bool submitting = false;
  List<PostReactionResponse> reactions = [];
  Map<String, String> userNames = {}; // cache userId -> name
  String? myUserId;

  // Map reaction strings to icons
  final Map<String, IconData> reactionIcons = {
    "LIKE": Icons.thumb_up,
    "LOVE": Icons.favorite,
    "WOW": Icons.sentiment_very_satisfied,
    "SAD": Icons.sentiment_dissatisfied,
    "ANGRY": Icons.sentiment_very_dissatisfied,
    "DIS_LIKE": Icons.thumb_down,
    "HAHA": Icons.mood,
    "CARE": Icons.healing,
    "SURPRISE": Icons.lightbulb,
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

  /// ---------- FETCH ALL REACTIONS ----------
  Future<void> _loadReactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    myUserId ??= prefs.getString('userId');

    final fetched = widget.postResponse.reactions;

    setState(() {
      reactions = fetched;
    });
  }

  /// ---------- GET USER NAME FROM USER ID ----------
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
      return body["name"] ?? "User";
    }
    return "User";
  }

  @override
  Widget build(BuildContext context) {
    // Group reactions by type and count for summary (only those with reaction)
    Map<String, int> reactionCounts = {};
    for (var r in reactions.where((r) => r.postReaction.value != null)) {
      reactionCounts[r.postReaction.value] =
          (reactionCounts[r.postReaction.value] ?? 0) + 1;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ---------- DISPLAY REACTION SUMMARY ----------
          if (reactionCounts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                children: reactionCounts.entries.map((entry) {
                  return Chip(
                    label: Text("${entry.value}"),
                    avatar: Icon(
                      reactionIcons[entry.key] ?? Icons.help_outline,
                      size: 16,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),

          /// ---------- DISPLAY REACTIONS AND COMMENTS LIST ----------
          if (reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reactions and Comments:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height:
                        300, // Fixed height for the list to prevent overflow
                    child: ListView.builder(
                      itemCount: reactions.length,
                      itemBuilder: (context, index) {
                        var r = reactions[index];
                        final userName = r.userName;
                        final reactionIcon = r.postReaction.value.isNotEmpty
                            ? Icon(
                                reactionIcons[r.postReaction.value] ??
                                    Icons.help_outline,
                                size: 16,
                              )
                            : null;
                        final isOwn = r.userId == myUserId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          title: Text(userName),
                          subtitle:
                              (r.postReaction.value.isNotEmpty ||
                                  r.comment != null)
                              ? Row(
                                  children: [
                                    if (reactionIcon != null) ...[
                                      reactionIcon,
                                      const SizedBox(width: 4),
                                    ],
                                    if (r.comment != null)
                                      Expanded(child: Text(r.comment!)),
                                  ],
                                )
                              : null,
                          trailing: isOwn
                              ? PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    if (value == 'Update') {
                                      _editReaction(r);
                                    } else if (value == 'Delete') {
                                      _deleteReaction(r.id!);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'Update',
                                      child: Text('Update'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'Delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          /// ---------- REACTIONS SELECTION FOR NEW ----------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: reactionIcons.keys
                  .map((reaction) => _reactionBtn(reaction))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          /// ---------- COMMENT BOX FOR NEW ----------
          TextField(
            controller: _commentController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Write a comment (optional)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),

          /// ---------- SUBMIT BUTTON FOR NEW ----------
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text("Submit"),
              onPressed: submitting
                  ? null
                  : () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Submitting reaction...."),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 10),
                                Text('In progress....'),
                              ],
                            ),
                          );
                        },
                      );

                      await _submitNew();

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  /// ---------- REACTION BUTTON ----------
  Widget _reactionBtn(String reaction) {
    final isSelected = selectedReaction == reaction;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Icon(reactionIcons[reaction] ?? Icons.help_outline),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            selectedReaction = isSelected ? null : reaction;
          });
        },
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  /// ---------- SUBMIT NEW REACTION + COMMENT ----------
  Future<void> _submitNew() async {
    final comment = _commentController.text.trim();
    if (selectedReaction == null && comment.isEmpty) {
      _showMsg("Please add a reaction or write a comment");
      return;
    }
    setState(() => submitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    final userId = prefs.getString('userId') ?? '';
    try {
      await ReactionService.addReaction(
        widget.postResponse.id,
        userId,
        selectedReaction,
        token,
        comment.isEmpty ? null : comment,
      );
      _commentController.clear();
      selectedReaction = null;
      _showMsg("Submitted successfully");
      await _loadReactions();
    } catch (e) {
      _showMsg("Submission failed");
    } finally {
      setState(() => submitting = false);
    }
  }

  /// ---------- EDIT REACTION ----------
  Future<void> _editReaction(PostReactionResponse r) async {
    String? editReaction = r.postReaction.value;
    final editCommentController = TextEditingController(text: r.comment ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Reaction'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: reactionIcons.keys.map((reaction) {
                        final isSelected = editReaction == reaction;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Icon(
                              reactionIcons[reaction] ?? Icons.help_outline,
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setDialogState(() {
                                editReaction = isSelected ? null : reaction;
                              });
                            },
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: editCommentController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Edit comment (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final comment = editCommentController.text.trim();
      if (editReaction == null && comment.isEmpty) {
        _showMsg("Please add a reaction or write a comment");
        editCommentController.dispose();
        return;
      }
      setState(() => submitting = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      try {
        await ReactionService.updateReaction(
          r.id,
          widget.postResponse.id,
          myUserId!,
          editReaction,
          token,
          comment.isEmpty ? null : comment,
        );
        _showMsg("Updated successfully");
        await _loadReactions();
      } catch (e) {
        _showMsg("Update failed");
        print("error in updating comments :- ${e.toString()}");
      } finally {
        setState(() => submitting = false);
      }
    }
    editCommentController.dispose();
  }

  /// ---------- DELETE REACTION ----------
  Future<void> _deleteReaction(String reactionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reaction'),
        content: const Text('Are you sure you want to delete this?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => submitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    try {
      await ReactionService.deleteReaction(reactionId, myUserId!, token);
      _showMsg("Deleted successfully");
      await _loadReactions();
    } catch (e) {
      _showMsg("Delete failed");
    } finally {
      setState(() => submitting = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
