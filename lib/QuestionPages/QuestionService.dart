import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as baseURL;
import 'QuestionModel.dart';

class QuestionService {
  static String get _base => "${baseURL.Urls().baseURL}questions";

  /// -------------------------------------------------
  /// COMMON HEADER
  /// -------------------------------------------------
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {"Authorization": "Bearer $token"};
  }

  /// -------------------------------------------------
  /// ASK QUESTION
  /// -------------------------------------------------
  static Future<QuestionModel> askQuestion({
    required String userId,
    required String message,
    required String questionType,
    File? file,                 // mobile
    Uint8List? webFileBytes,    // web
    String? fileName,
  }) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$_base/ask"),
    );

    request.headers.addAll(await _headers());

    request.fields.addAll({
      "userId": userId,
      "usersId": userId,
      "message": message,
      "questionType": questionType,
    });

    // 🌐 WEB
    if (kIsWeb && webFileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          webFileBytes,
          filename: fileName ?? "attachment",
        ),
      );
    }

    // 📱 MOBILE
    if (!kIsWeb && file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return QuestionModel.fromJson(jsonDecode(body));
    } else {
      throw Exception(body);
    }
  }


  /// -------------------------------------------------
  /// UPDATE QUESTION
  /// -------------------------------------------------
  static Future<QuestionModel> updateQuestion({
    required String questionId,
    required String userId,
    required String message,
    required String questionType,
    required String attachmentId,
    File? file,
    File? pickedImage,
    Uint8List? webFileBytes,
    String? fileName,
  }) async {
    final request = http.MultipartRequest("PUT", Uri.parse("$_base/update"));

    request.headers.addAll(await _headers());

    request.fields.addAll({
      "questionId": questionId,
      "usersId": userId,
      "userId": userId,
      "message": message,
      "questionType": questionType,
      "attachmentId": attachmentId,
    });

    if (file != null) {
      if (kIsWeb) {
        webFileBytes = await file.readAsBytes();
        pickedImage = File(file.path);

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webFileBytes,
            filename: fileName ?? "attachment",
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            filename: fileName,
          ),
        );
      }
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return QuestionModel.fromJson(jsonDecode(body));
    } else {
      throw Exception(body);
    }
  }

  /// -------------------------------------------------
  /// DELETE QUESTION
  /// -------------------------------------------------
  static Future<bool> deleteQuestion({
    required String questionId,
    required String userId,
  }) async {
    final res = await http.delete(
      Uri.parse("$_base/$questionId?userId=$userId"),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception(res.body);
    }
  }

  /// -------------------------------------------------
  /// GET ALL QUESTIONS
  /// -------------------------------------------------
  static Future<List<QuestionModel>> getAllQuestions() async {
    final res = await http.get(
      Uri.parse("$_base/all"),
      headers: await _headers(),
    );

    return _parseList(res);
  }

  /// -------------------------------------------------
  /// GET QUESTIONS BY USER
  /// -------------------------------------------------
  static Future<List<QuestionModel>> getByUser(String userId) async {
    final res = await http.get(
      Uri.parse("$_base/user/$userId"),
      headers: await _headers(),
    );

    return _parseList(res);
  }

  /// -------------------------------------------------
  /// SEARCH BY KEYWORD
  /// -------------------------------------------------
  static Future<List<QuestionModel>> search(String keyword) async {
    final res = await http.get(
      Uri.parse("$_base/search?keyword=$keyword"),
      headers: await _headers(),
    );

    return _parseList(res);
  }

  /// -------------------------------------------------
  /// FILTER BY QUESTION TYPE
  /// -------------------------------------------------
  static Future<List<QuestionModel>> filterByType(String type) async {
    final res = await http.get(
      Uri.parse("$_base/type/$type"),
      headers: await _headers(),
    );

    return _parseList(res);
  }

  /// -------------------------------------------------
  /// FILTER BETWEEN TIME
  /// -------------------------------------------------
  static Future<List<QuestionModel>> findBetween(
    DateTime start,
    DateTime end,
  ) async {
    final res = await http.get(
      Uri.parse(
        "$_base/between?start=${start.toIso8601String()}&end=${end.toIso8601String()}",
      ),
      headers: await _headers(),
    );

    return _parseList(res);
  }

  /// -------------------------------------------------
  /// FILTER AFTER TIME
  /// -------------------------------------------------
  static Future<List<QuestionModel>> findAfter(DateTime time) async {
    final res = await http.get(
      Uri.parse("$_base/after?time=${time.toIso8601String()}"),
      headers: await _headers(),
    );

    return _parseList(res);
  }

  /// -------------------------------------------------
  /// FILTER BEFORE TIME
  /// -------------------------------------------------
  static Future<List<QuestionModel>> findBefore(DateTime time) async {
    final res = await http.get(
      Uri.parse("$_base/before?time=${time.toIso8601String()}"),
      headers: await _headers(),
    );

    return _parseList(res);
  }

  /// -------------------------------------------------
  /// FIND BY QUESTION ID
  /// -------------------------------------------------
  static Future<QuestionModel> findById(String id) async {
    final res = await http.get(
      Uri.parse("$_base/findByQuestionId?questionId=$id"),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      return QuestionModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception(res.body);
    }
  }

  /// -------------------------------------------------
  /// DOWNLOAD ATTACHMENT
  /// -------------------------------------------------
  static Future<http.Response> downloadAttachment(String attachmentId) async {
    return await http.get(
      Uri.parse("$_base/downloadQuestionContent?attachmentId=$attachmentId"),
      headers: await _headers(),
    );
  }

  /// -------------------------------------------------
  /// PARSER
  /// -------------------------------------------------
  static List<QuestionModel> _parseList(http.Response res) {
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => QuestionModel.fromJson(e)).toList();
    } else {
      throw Exception(res.body);
    }
  }
}
