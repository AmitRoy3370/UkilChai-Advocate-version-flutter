// lib/HomePage/latest_questions_widget.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../QuestionPages/QuestionModel.dart';
import '../QuestionPages/question_response.dart';
import '../QuestionPages/QuestionService.dart';
import '../Utils/AdvocateSpeciality.dart';
import '../QuestionPages/QuestionListPage.dart';
import '../QuestionPages/QuestionAttachmentViewer.dart';
import '../QuestionPages/question_attachment_widget.dart';
import '../QuestionPages/AnswerTile.dart';
import '../Utils/BaseURL.dart' as baseURL;

class LatestQuestionsWidget extends StatefulWidget {
  /// How many latest questions to fetch. Defaults to 4.
  final int count;

  /// Optional callback when the user taps a question card.
  /// If null, opens a lightweight inline preview.
  final void Function(QuestionResponse)? onQuestionTap;

  /// Optional: bump this key from the parent to force a reload.
  final Key? refreshKey;

  const LatestQuestionsWidget({
    super.key,
    this.count = 4,
    this.onQuestionTap,
    this.refreshKey,
  });

  @override
  State<LatestQuestionsWidget> createState() => _LatestQuestionsWidgetState();
}

class _LatestQuestionsWidgetState extends State<LatestQuestionsWidget> {
  bool _loading = true;
  String? _error;
  List<QuestionResponse> _questions = const [];
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LatestQuestionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.count != widget.count) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await QuestionService.getAllPaginated(
        page: 0,
        size: widget.count,
        sort: 'postTime,desc',
      );

      final parsed = (page.responses as List)
          .whereType<QuestionResponse>()
          .toList();
      parsed.sort((a, b) => b.postTime.compareTo(a.postTime));

      if (!mounted) return;
      setState(() {
        _questions = parsed.take(widget.count).toList(growable: false);
        _hasMore = page.totalElement > _questions.length || page.hasNext;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openQuestion(QuestionResponse q) {
    if (widget.onQuestionTap != null) {
      widget.onQuestionTap!(q);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _QuestionPreviewPage(question: q, onRefresh: _load)),
    ).then((_) => _load()); // Refresh the list when coming back
  }

  void _openSeeAll() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuestionListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            count: _questions.length,
            onRefresh: _loading ? null : _load,
          ),
          const SizedBox(height: 10),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.green,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _load);
    }

    if (_questions.isEmpty) {
      return _EmptyState(onRetry: _load);
    }

    return Column(
      children: [
        for (var i = 0; i < _questions.length; i++) ...[
          _QuestionTile(
            question: _questions[i],
            onTap: () => _openQuestion(_questions[i]),
          ),
          if (i != _questions.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 10),
        _SeeAllButton(
          onPressed: _openSeeAll,
          label: _hasMore ? 'See All Questions' : 'Refresh',
          icon: _hasMore
              ? Icons.arrow_forward_rounded
              : Icons.refresh_rounded,
        ),
      ],
    );
  }
}

// =============================================================================
// ============================== HEADER =======================================
// =============================================================================
class _Header extends StatelessWidget {
  final int count;
  final VoidCallback? onRefresh;

  const _Header({required this.count, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Latest Questions',
          style: TextStyle(
            color: Colors.green.shade800,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onRefresh,
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.green.shade700,
              size: 20,
            ),
            tooltip: 'Refresh',
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ============================ QUESTION TILE ==================================
// =============================================================================
class _QuestionTile extends StatelessWidget {
  final QuestionResponse question;
  final VoidCallback onTap;

  const _QuestionTile({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(question.questionType.label);
    final when = _relativeTime(question.postTime);
    final preview = question.message.trim().replaceAll('\n', ' ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      preview.isEmpty ? 'Untitled question' : preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1B2430),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Chip(label: question.questionType.label, color: typeColor),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      question.userName.isEmpty ? '—' : question.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.question_answer_outlined,
                      size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Text(
                    '${question.totalAnswers}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (question.hasAttachment) ...[
                    Icon(Icons.attach_file,
                        size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                  ],
                  Icon(Icons.schedule,
                      size: 11, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(
                    when,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _typeColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('CRIMINAL')) return const Color(0xFFEF4444);
    if (t.contains('CIVIL')) return const Color(0xFF3B82F6);
    if (t.contains('DIVORCE') || t.contains('FAMILY')) {
      return const Color(0xFFA855F7);
    }
    if (t.contains('PROPERTY')) return const Color(0xFFF59E0B);
    if (t.contains('CORPORATE') || t.contains('COMPANY')) {
      return const Color(0xFF10B981);
    }
    if (t.contains('LABOR') || t.contains('LABOUR')) {
      return const Color(0xFF0EA5E9);
    }
    return const Color(0xFF14B8A6);
  }

  static String _relativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${time.day} ${months[time.month - 1]} ${time.year}';
  }
}

// =============================================================================
// ============================== CHIP =========================================
// =============================================================================
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// =============================================================================
// ============================== SEE ALL BUTTON ===============================
// =============================================================================
class _SeeAllButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const _SeeAllButton({
    required this.onPressed,
    this.label = 'See All',
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade300),
              color: Colors.green.shade50,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(icon, color: Colors.green.shade800, size: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ============================== STATE VIEWS ==================================
// =============================================================================
class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.question_answer_outlined,
              color: Colors.green.shade300, size: 34),
          const SizedBox(height: 6),
          const Text(
            'No questions yet',
            style: TextStyle(
              color: Color(0xFF1B2430),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Be the first to ask a legal question',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, size: 14, color: Colors.green.shade700),
            label: Text(
              'Retry',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEDED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF8C4C4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFDC2626), size: 32),
          const SizedBox(height: 6),
          const Text(
            'Failed to load questions',
            style: TextStyle(
              color: Color(0xFF7F1D1D),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              error,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 10.5),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 14, color: Color(0xFFDC2626)),
            label: const Text(
              'Retry',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ========================== QUESTION PREVIEW PAGE ============================
// =============================================================================
class _QuestionPreviewPage extends StatefulWidget {
  final QuestionResponse question;
  final VoidCallback onRefresh; // ✅ Added to refresh parent list
  const _QuestionPreviewPage({required this.question, required this.onRefresh});

  @override
  State<_QuestionPreviewPage> createState() => _QuestionPreviewPageState();
}

class _QuestionPreviewPageState extends State<_QuestionPreviewPage> {
  String myLoggedInToken = "";
  
  // ✅ Answer State
  final TextEditingController answerController = TextEditingController();
  PlatformFile? answerFile;
  String? answerFileName;
  String? answerFileExtension;
  bool isAdvocate = false;
  String currentAdvocateId = "";
  String currentUserId = "";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      myLoggedInToken = prefs.getString('jwt_token') ?? '';
      currentAdvocateId = prefs.getString('advocateId') ?? '';
      currentUserId = prefs.getString('userId') ?? '';
      isAdvocate = currentAdvocateId.isNotEmpty;
    });
  }

  void _navigateToAttachmentViewer(String attachmentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionAttachmentViewer(
          attachmentId: attachmentId,
          jwtToken: myLoggedInToken,
        ),
      ),
    );
  }

  // ✅ Answer File Picker
  Future<void> pickAnswerFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );
    if (result == null) return;
    final file = result.files.first;
    setState(() {
      answerFile = file;
      answerFileName = file.name;
      answerFileExtension = file.extension;
    });
  }

  String? getMimeType(String? extension) {
    if (extension == null) return null;
    extension = extension.toLowerCase();
    switch (extension) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'pdf': return 'application/pdf';
      case 'mp4': return 'video/mp4';
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt': return 'text/plain';
      case 'json': return 'application/json';
      default: return 'application/octet-stream';
    }
  }

  // ✅ Submit Answer logic
  Future<void> answerQuestion() async {
    if (answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an answer message")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(height: 16),
              Text(
                "Posting your answer...",
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${baseURL.Urls().baseURL}answers/add"),
      );

      request.headers['Authorization'] = 'Bearer $myLoggedInToken';

      request.fields['advocateId'] = currentAdvocateId;
      request.fields['message'] = answerController.text.trim();
      request.fields['questionId'] = widget.question.id;
      request.fields['userId'] = currentUserId;

      if (answerFile != null) {
        final mimeTypeStr = getMimeType(answerFileExtension);
        http.MediaType? contentType = mimeTypeStr != null
            ? http.MediaType.parse(mimeTypeStr)
            : null;

        if (kIsWeb) {
          if (answerFile!.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                "file",
                answerFile!.bytes!,
                filename: answerFile!.name,
                contentType: contentType,
              ),
            );
          }
        } else {
          if (answerFile!.path != null) {
            request.files.add(
              await http.MultipartFile.fromPath(
                "file",
                answerFile!.path!,
                filename: answerFile!.name,
                contentType: contentType,
              ),
            );
          } else if (answerFile!.bytes != null) {
            request.files.add(
              http.MultipartFile.fromBytes(
                "file",
                answerFile!.bytes!,
                filename: answerFile!.name,
                contentType: contentType,
              ),
            );
          }
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (context.mounted) Navigator.pop(context); // Close loading

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Answer posted successfully!", style: GoogleFonts.inter()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        answerController.clear();
        setState(() {
          answerFile = null;
          answerFileName = null;
          answerFileExtension = null;
        });
        
        // ✅ Refresh parent list
        widget.onRefresh();
        
        // Close page to see the fresh data
        if (mounted) Navigator.pop(context);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to post answer: ${response.statusCode}", style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error posting answer: $e", style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final answers = question.answers;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        title: Text(
          question.formattedQuestionType,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Author + time
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  question.userName.isEmpty ? '—' : question.userName,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                question.formattedPostTime,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question body
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Text(
              question.message,
              style: TextStyle(
                color: Colors.grey.shade900,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),

          // Attachment
          if (question.hasAttachment) ...[
            const SizedBox(height: 12),
            QuestionAttachmentWidget(
              attachmentId: question.attachmentId!,
              height: 200,
              onViewAttachment: _navigateToAttachmentViewer,
            ),
          ],

          const SizedBox(height: 20),
          Text(
            'Answers (${answers.length})',
            style: TextStyle(
              color: Colors.grey.shade900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          
          // Answers List
          if (answers.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  "Be the first to answer this question",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            Column(
              children: answers.map((a) => AnswerTile(answer: a)).toList(),
            ),

          // ✅ Advocate Answer Input Section
          if (isAdvocate) ...[
            const Divider(color: Colors.grey, height: 32),
            Text(
              "Your Answer",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: answerController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Write your answer here...",
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickAnswerFile,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text("Attach File"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (answerFileName != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      answerFileName!,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.green),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: answerQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Post Answer",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}