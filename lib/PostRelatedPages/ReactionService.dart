import 'dart:convert';
import 'dart:io';
import 'package:advocatechaiadvocate/PostRelatedPages/post_reaction_response.dart';
import 'package:http/http.dart' as http;
import '../Utils/BaseURL.dart' as BASE_URL;
import 'PostReaction.dart';

class ReactionService {

  static String get _base =>
      "${BASE_URL.Urls().baseURL}post-reactions";

  /// ---------- FETCH REACTIONS BY POST ----------
  static Future<List<PostReactionResponse>> fetchByPost(
      String postId, String token) async {

    final res = await http.get(
      Uri.parse("$_base/post/$postId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => PostReactionResponse.fromJson(e)).toList();
    }

    return [];
  }

  /// ---------- ADD REACTION + OPTIONAL COMMENT ----------
  static Future<PostReaction?> addReaction(
      String postId,
      String userId,
      String? reaction,
      String token,
      String? comment,
      ) async {

    final res = await http.post(
      Uri.parse("$_base/add"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "advocatePostId": postId,
        "userId": userId,
        "postReaction": reaction,
        "comment": comment,
      }),
    );

    if (res.statusCode == 200) {
      return PostReaction.fromJson(jsonDecode(res.body));
    }

    throw Exception(
      "Failed to add reaction: ${res.body}",
    );
  }

  /// ---------- UPDATE REACTION ----------
  static Future<PostReaction?> updateReaction(
      String reactionId,
      String postId,
      String userId,
      String? reaction,
      String token,
      String? comment,
      ) async {

    final res = await http.put(
      Uri.parse("$_base/update/$reactionId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": userId,
        "postReaction": reaction,
        "comment": comment,
        "advocatePostId":postId
      }),
    );

    if (res.statusCode == 200) {
      return PostReaction.fromJson(jsonDecode(res.body));
    }

    throw Exception(res.body);
  }

  /// ---------- DELETE REACTION ----------
  static Future<bool> deleteReaction(
      String reactionId,
      String userId,
      String token,
      ) async {

    final res = await http.delete(
      Uri.parse("$_base/$reactionId?userId=$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return res.statusCode == 200;
  }

  /// ---------- FETCH REACTIONS BY USER ----------
  static Future<List<PostReactionResponse>> fetchByUser(
      String userId, String token) async {

    final res = await http.get(
      Uri.parse("$_base/user/$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => PostReactionResponse.fromJson(e)).toList();
    }

    return [];
  }

}
