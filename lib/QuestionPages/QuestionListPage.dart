import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;
import 'package:advocatechaiadvocate/QuestionPages/question_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as baseURL;
import 'QuestionCard.dart';
import 'QuestionModel.dart';
import 'QuestionService.dart';
import 'package:http/http.dart' as http;
import 'package:advocatechaiadvocate/Utils/BaseURL.dart' as BASEURL;

class QuestionListPage extends StatefulWidget {
  const QuestionListPage({super.key});

  @override
  State<QuestionListPage> createState() => _QuestionListPageState();
}

class _QuestionListPageState extends State<QuestionListPage> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Legal Q&A"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (v) => setState(() => searchText = v),
              decoration: InputDecoration(
                hintText: "Search question or answer...",
                filled: true,
                fillColor: Colors.white70,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<QuestionResponse>>(
        future: searchText.isEmpty
            ? QuestionService.getAllQuestions()
            : QuestionService.search(searchText),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: questions.length,
            itemBuilder: (context, i) {
              return QuestionCard(question: questions[i], refreshMethod: () {
                setState(() {});
              });
            },
          );
        },
      ),
    );
  }
}
