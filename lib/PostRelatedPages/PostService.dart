import 'dart:convert';
import 'package:http/http.dart' as http;
import './AdvocatePost.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class PostService {
  static Future<List<AdvocatePost>> fetchAllPosts(String token) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}advocate/posts/all"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) throw Exception("Failed to load posts");

    final List data = jsonDecode(res.body);
    return data.map((e) => AdvocatePost.fromJson(e)).toList();
  }

  static Future<List<AdvocatePost>> searchPosts(
    String keyword,
    String token,
  ) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate/posts/search?keyword=$keyword",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    final List data = jsonDecode(res.body);
    return data.map((e) => AdvocatePost.fromJson(e)).toList();
  }

  static Future<List<AdvocatePost>> fetchSpecificAdvocatesPosts(
    String? advocateId,
    String token,
  ) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate/posts/advocate/$advocateId",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) throw Exception("Failed to load posts");

    final List data = jsonDecode(res.body);
    return data.map((e) => AdvocatePost.fromJson(e)).toList();
  }

  static Future<int> deletePost(
    String? postId,
    String? userId,
    String? token,
  ) async {
    final response = await http.delete(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate/posts/delete/$postId/$userId",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode;
  }
}
