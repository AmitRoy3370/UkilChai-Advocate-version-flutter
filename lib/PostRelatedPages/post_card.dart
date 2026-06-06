import 'dart:convert';
import 'package:advocatechaiadvocate/PostRelatedPages/post_response.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/AdvocateSpeciality.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './AdvocatePost.dart';
import 'PostAttachmentViewer.dart';
import 'reaction_bar.dart';

class PostCard extends StatefulWidget {
  final PostResponse post;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function? onReactionChanged;
  final bool? canReact;

  const PostCard({
    super.key, 
    required this.post, 
    this.onEdit, 
    this.onDelete, 
    this.onReactionChanged, 
    this.canReact
  });

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

  @override
  State<StatefulWidget> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Check if attachment exists - moved inside state class
  bool get hasAttachment {
    return widget.post.attachmentId != null &&
        widget.post.attachmentId!.isNotEmpty &&
        widget.post.attachmentId != "null" &&
        widget.post.attachmentId != "attachmentId";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.green.shade400, Colors.green.shade600],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.post.advocateName.isNotEmpty
                              ? widget.post.advocateName[0].toUpperCase()
                              : "A",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.advocateName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade400, Colors.green.shade600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.post.postType.label,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Edit/Delete buttons
                    if (widget.onEdit != null || widget.onDelete != null)
                      Row(
                        children: [
                          if (widget.onEdit != null)
                            IconButton(
                              icon: Icon(Icons.edit, size: 20, color: Colors.grey[600]),
                              onPressed: widget.onEdit,
                            ),
                          if (widget.onDelete != null)
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                              onPressed: widget.onDelete,
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Post Content
                Text(
                  widget.post.postContent,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Attachment Button - Only shows if attachment exists
                if (hasAttachment)
                  InkWell(
                    onTap: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('jwt_token') ?? '';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostAttachmentView(
                            attachmentId: widget.post.attachmentId!,
                            jwtToken: token,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file, size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            "View Attachment",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new, size: 14, color: Colors.green),
                        ],
                      ),
                    ),
                  ),

                const Divider(color: Colors.grey, height: 24),

                // Reaction Bar
                ReactionBar(
                  postResponse: widget.post,
                  onReactionChanged: (reaction, action) {
                    setState(() {
                      switch (action) {
                        case 'add':
                          widget.post.reactions.insert(0, reaction);
                          break;
                        case 'remove':
                          widget.post.reactions.removeWhere((r) => r.id == reaction.id);
                          break;
                        case 'update':
                          final index = widget.post.reactions.indexWhere((r) => r.id == reaction.id);
                          if (index != -1) {
                            widget.post.reactions[index] = reaction;
                          }
                          break;
                      }
                    });
                    widget.onReactionChanged?.call(reaction, action);
                  },
                  canReact: widget.canReact ?? true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}