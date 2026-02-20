import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as BASEURL;
import 'AnswerModel.dart';

class AnswerService {
  static Future<List<AnswerModel>> getByQuestion(String questionId) async {
    final token = await AuthService.getToken();

    final res = await http.get(
      Uri.parse(
        "${BASEURL.Urls().baseURL}answers/by-question/$questionId",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => AnswerModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<AnswerModel>> search(String keyword) async {
    final token = await AuthService.getToken();

    final res = await http.get(
      Uri.parse(
        "${BASEURL.Urls().baseURL}answers/search?keyword=$keyword",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => AnswerModel.fromJson(e))
          .toList();
    }
    return [];
  }
}
