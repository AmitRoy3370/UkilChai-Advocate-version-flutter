import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import './AdvocatePost.dart';
import 'PostAttachmentViewer.dart';
import 'reaction_bar.dart';
import '../PageTransition.dart';
import 'attachment_widget.dart';
import '../AdvocatePages/AdvocateDetails.dart';
import '../AdvocatePages/AdvocateDetailsModel.dart';
import '../Utils/AdvocateSpeciality.dart'; 
import '../PostRelatedPages/post_response.dart';

class PostCard extends StatefulWidget {
  final PostResponse post;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool? canReact;
  final Function? onReactionChanged;

  const PostCard({
    super.key,
    required this.post,
    this.onEdit,
    this.onDelete,
    this.canReact,
    this.onReactionChanged,
  });

  @override
  State<StatefulWidget> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final List<PageTransitionType> _smoothAnimations = AnimatedRoute.getCompanySafeAnimations();
  
  bool _isExpanded = false;
  static const int _maxLines = 3;
  static const int _minCharLength = 100;

  PageTransitionType _getRandomAnimation() {
    final random = Random().nextInt(_smoothAnimations.length);
    return _smoothAnimations[random];
  }

  bool get hasAttachment {
    return widget.post.attachmentId != null &&
        widget.post.attachmentId!.isNotEmpty &&
        widget.post.attachmentId != "null" &&
        widget.post.attachmentId != "attachmentId";
  }

  // Helper getter to check if title exists and is not empty
  bool get _hasTitle =>
      widget.post.postTitle != null && widget.post.postTitle!.trim().isNotEmpty;

  bool get _isLongContent {
    return widget.post.postContent.length > _minCharLength;
  }

  void _navigateToAttachmentViewer(String attachmentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostAttachmentView(
          attachmentId: attachmentId,
          jwtToken: token,
        ),
      ),
    );
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
                // ========== হেডার ==========
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
                          colors: [Colors.purple.shade400, Colors.blue.shade400],
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
                          GestureDetector(
                            onTap: () async {
                              final response = await http.get(
                                Uri.parse("${BASE_URL.Urls().baseURL}advocate/${widget.post.advocateId}")
                              );
                              
                              if (response.statusCode == 200) {
                                final Map<String, dynamic> responseData = jsonDecode(response.body);
                                final AdvocateDetailsModel advocate = AdvocateDetailsModel.fromJson(responseData);
                                
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdvocateDetails(advocateDetailsModel: advocate),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              widget.post.advocateFullName ?? widget.post.advocateName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.shade600, 
                                  Colors.blue.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.post.postType.icon,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.post.postType.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ========== EDIT / DELETE BUTTONS (For Advocate Panel) ==========
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

                // ========== POST TITLE (Conditional) ==========
                if (_hasTitle) ...[
                  const SizedBox(height: 14),
                  Text(
                    widget.post.postTitle!,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                      height: 1.35,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ========== পোস্ট কন্টেন্ট (See More/Less সহ) ==========
                _buildPostContent(),
                
                const SizedBox(height: 12),

                // ========== অ্যাটাচমেন্ট উইজেট ==========
                if (hasAttachment)
                  AttachmentWidget(
                    attachmentId: widget.post.attachmentId!,
                    height: 150,
                    onViewAttachment: _navigateToAttachmentViewer,
                  ),

                const Divider(color: Colors.grey, height: 24),

                // ========== রিঅ্যাকশন বার ==========
                ReactionBar(
                  postResponse: widget.post,
                  onReactionChanged: (reaction, action) {
                    setState(() {
                      widget.onReactionChanged?.call(reaction, action);
                    });
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

  Widget _buildPostContent() {
    final text = widget.post.postContent;
    
    if (!_isLongContent) {
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.grey[700],
          height: 1.4,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.4,
          ),
          maxLines: _isExpanded ? null : _maxLines,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isExpanded ? 'See less' : 'See more',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.blue.shade600,
              ),
            ],
          ),
        ),
      ],
    );
  }
}