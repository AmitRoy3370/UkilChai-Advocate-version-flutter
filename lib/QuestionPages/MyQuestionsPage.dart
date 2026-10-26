// lib/QuestionPages/MyQuestionsPage.dart
//
// Mirrors QuestionListPage but shows ONLY the current user's questions.
// Uses QuestionService.getByUser(userId) instead of getAllQuestions().

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/AuthService.dart';
import 'QuestionCard.dart';
import 'QuestionService.dart';
import 'question_response.dart';

class MyQuestionsPage extends StatefulWidget {
  const MyQuestionsPage({super.key});

  @override
  State<MyQuestionsPage> createState() => _MyQuestionsPageState();
}

class _MyQuestionsPageState extends State<MyQuestionsPage> {
  String searchText = "";
  String? _userId;
  bool _loadingUserId = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      // Try the standard helper first
      String? id = await AuthService.getUserId();

      // Fallback: read directly from SharedPreferences
      if (id == null || id.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        id = prefs.getString('userId');
      }

      if (!mounted) return;
      setState(() {
        _userId = id;
        _loadingUserId = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingUserId = false;
      });
    }
  }

  /// Filters questions client-side by keyword.
  /// Used only when the search box has text, since the "by user" endpoint
  /// doesn't support a keyword parameter.
  List<QuestionResponse> _applySearch(List<QuestionResponse> list) {
    if (searchText.trim().isEmpty) return list;
    final q = searchText.toLowerCase().trim();

    return list.where((item) {
      // Match on the question text
      if (item.message.toLowerCase().contains(q)) return true;

      // Match on userName / fullName
      final name = (item.fullName ?? item.userName).toLowerCase();
      if (name.contains(q)) return true;

      // Match on any answer text
      // ⚠️ Change `.message` below to whichever field your
      //    AnswerResponse uses for the answer body.
      for (final a in item.answers) {
        if (a.message.toLowerCase().contains(q)) return true;
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "My Questions",
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Still resolving the userId
    if (_loadingUserId) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(height: 16),
            Text(
              'Loading your questions...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // No user logged in / userId missing
    if (_userId == null || _userId!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view your questions',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Bar (client-side filter)
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
              hintText: "Search your questions...",
              hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.purple),
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
            future: QuestionService.getByUser(_userId!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.purple),
                      SizedBox(height: 16),
                      Text(
                        'Loading your questions...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              List<QuestionResponse> questions = snapshot.data!;
              questions = questions.reversed.toList();

              // Apply client-side keyword filter
              questions = _applySearch(questions);

              if (questions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.question_answer_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchText.isEmpty
                            ? "You haven't asked any questions yet"
                            : 'No matching questions',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        searchText.isEmpty
                            ? 'Your asked questions will appear here'
                            : 'Try a different search term',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
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
    );
  }
}