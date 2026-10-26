import 'dart:convert';
import 'dart:math';
import '../PostRelatedPages/post_response.dart';
import '../Utils/AdvocateSpeciality.dart';
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

class SinglePostPage extends StatefulWidget {
  final PostResponse post;
  final bool? canReact;
  final Function? onReactionChanged;

  const SinglePostPage({
    super.key,
    required this.post,
    this.canReact,
    this.onReactionChanged,
  });

  @override
  State<StatefulWidget> createState() => _SinglePostPageState();
}

class _SinglePostPageState extends State<SinglePostPage> {
  // Smooth animations only
  final List<PageTransitionType> _smoothAnimations = AnimatedRoute.getCompanySafeAnimations();
  
  // ========== See More/Less এর জন্য ==========
  bool _isExpanded = false;
  
  // ========== পোস্ট কন্টেন্টের লাইন সংখ্যা ==========
  static const int _maxLines = 3;
  static const int _minCharLength = 100; // ১০০ ক্যারেক্টারের বেশি হলে See More দেখাবে

  PageTransitionType _getRandomAnimation() {
    final random = Random().nextInt(_smoothAnimations.length);
    return _smoothAnimations[random];
  }

  // Check if attachment exists
  bool get hasAttachment {
    return widget.post.attachmentId != null &&
        widget.post.attachmentId!.isNotEmpty &&
        widget.post.attachmentId != "null" &&
        widget.post.attachmentId != "attachmentId";
  }

  // ========== কন্টেন্ট লম্বা কিনা চেক ==========
  bool get _isLongContent {
    return widget.post.postContent.length > _minCharLength;
  }

  // ========== অ্যাটাচমেন্ট ভিউয়ারের জন্য নেভিগেশন ==========
  void _navigateToAttachmentViewer(String attachmentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to view attachment')),
      );
      return;
    }

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
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    child: Container(
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
              mainAxisSize: MainAxisSize.min, // 🔥 এটা যোগ করুন
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
                          Text(
                            widget.post.advocateFullName ?? widget.post.advocateName,
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
                                colors: [Colors.purple.shade400, Colors.blue.shade400],
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
                  ],
                ),
                const SizedBox(height: 12),

                // ========== পোস্ট কন্টেন্ট ==========
                _buildPostContent(),
                
                const SizedBox(height: 12),

                // ========== অ্যাটাচমেন্ট ==========
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
    ),
  );
}

  // ========== পোস্ট কন্টেন্ট বিল্ডার (See More/Less সহ) ==========
  Widget _buildPostContent() {
    final text = widget.post.postContent;
    
    // কন্টেন্ট ছোট হলে সরাসরি দেখান
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

    // লম্বা কন্টেন্ট - See More/Less সহ
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