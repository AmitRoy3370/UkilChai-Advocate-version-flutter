// QuestionListPage.dart (Advocate Panel)
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../QuestionPages/question_response.dart';
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as baseURL;
import 'QuestionCard.dart';
import 'QuestionModel.dart';
import 'QuestionService.dart';
import '../PageTransition.dart';

class QuestionListPage extends StatefulWidget {
  String? type;
  QuestionListPage({super.key, this.type});

  @override
  State<QuestionListPage> createState() => _QuestionListPageState();
}

class _QuestionListPageState extends State<QuestionListPage> {
  String searchText = "";

  final List<PageTransitionType> _smoothAnimations =
      AnimatedRoute.getCompanySafeAnimations();

  PageTransitionType _getRandomAnimation() {
    final random = Random().nextInt(_smoothAnimations.length);
    return _smoothAnimations[random];
  }

  // ============================================================
  // ✅ Single place to build the future — swallows errors into []
  // ============================================================
  Future<List<QuestionResponse>> _loadQuestions() async {
    try {
      if (searchText.isNotEmpty) {
        return await QuestionService.search(searchText);
      }
      if (widget.type != null && widget.type!.isNotEmpty) {
        return await QuestionService.filterByType(widget.type!);
      }
      return await QuestionService.getAllQuestions();
    } catch (e) {
      // Any "no questions found", 404, parse error, etc. → empty list
      print('⚠️ QuestionListPage load error: $e');
      return <QuestionResponse>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Legal Q&A",
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => searchText = v),
              style: GoogleFonts.inter(color: Colors.grey[800]),
              decoration: InputDecoration(
                hintText: "Search question or answer...",
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.purple),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Questions List
          Expanded(
            child: FutureBuilder<List<QuestionResponse>>(
              future: _loadQuestions(),
              builder: (context, snapshot) {
                // ✅ 1. Loading state — only while waiting
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.purple),
                        SizedBox(height: 16),
                        Text(
                          'Loading questions...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // ✅ 2. Error state — never stays stuck
                if (snapshot.hasError) {
                  return _buildEmptyState(
                    title: 'Could not load questions',
                    subtitle: snapshot.error.toString(),
                    icon: Icons.error_outline,
                  );
                }

                // ✅ 3. Data (or empty) state
                List<QuestionResponse> questions =
                    snapshot.data ?? <QuestionResponse>[];
                questions = questions.reversed.toList();

                if (questions.isEmpty) {
                  return _buildEmptyState(
                    title: searchText.isEmpty
                        ? (widget.type == null
                            ? 'No questions yet'
                            : 'No questions in this category')
                        : 'No matching questions',
                    subtitle: searchText.isEmpty
                        ? (widget.type == null
                            ? 'Be the first to ask a question'
                            : 'Try another category')
                        : 'Try a different search term',
                    icon: Icons.question_answer_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  color: Colors.purple,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: questions.length,
                    itemBuilder: (context, i) {
                      return QuestionCard(
                        question: questions[i],
                        refreshMethod: () {
                          setState(() {});
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ Shared empty/error state widget
  // ============================================================
  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}