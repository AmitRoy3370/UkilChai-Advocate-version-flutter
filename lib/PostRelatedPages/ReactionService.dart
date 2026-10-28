import 'dart:convert';
import 'package:http/http.dart' as http;
import '../PostRelatedPages/post_reaction.dart';
import '../PostRelatedPages/post_reaction_response.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class ReactionService {
  static String get _base => "${BASE_URL.Urls().baseURL}post-reactions";

  // ==================== FETCH BY POST ====================
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

  // ==================== ADD REACTION + OPTIONAL COMMENT ====================
  static Future<PostReaction?> addReaction(
    String postId,
    String userId,
    String? reaction,
    String token,
    String? comment,
  ) async {
    final Map<String, dynamic> requestBody = {
      "advocatePostId": postId,
      "userId": userId,
    };

    if (reaction != null && reaction.isNotEmpty) {
      requestBody["postReaction"] = reaction;
    }
    if (comment != null && comment.isNotEmpty) {
      requestBody["comment"] = comment;
    }

    print("Request Body: $requestBody");

    final res = await http.post(
      Uri.parse("$_base/add"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(requestBody),
    );

    print("reaction add body :- ${res.body} and status :- ${res.statusCode}");

    if (res.statusCode == 201 || res.statusCode == 200) {
      return PostReaction.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to add reaction: ${res.body}");
  }

  // ==================== UPDATE REACTION ====================
  static Future<PostReaction?> updateReaction(
    String reactionId,
    String postId,
    String userId,
    String? reaction,
    String token,
    String? comment,
  ) async {
    final Map<String, dynamic> requestBody = {
      "advocatePostId": postId,
      "userId": userId,
    };

    if (reaction != null && reaction.isNotEmpty) {
      requestBody["postReaction"] = reaction;
    }
    if (comment != null && comment.isNotEmpty) {
      requestBody["comment"] = comment;
    }

    print("Request Body: $requestBody");

    final res = await http.put(
      Uri.parse("$_base/update/$reactionId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(requestBody),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return PostReaction.fromJson(jsonDecode(res.body));
    }
    throw Exception(res.body);
  }

  // ==================== DELETE REACTION ====================
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

  // ==================== FETCH BY USER ====================
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

  // ==================== GET BY ID ====================
  static Future<PostReactionResponse> getById(String id, {String? token}) async {
    final res = await http.get(
      Uri.parse("$_base/$id"),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      return PostReactionResponse.fromJson(jsonDecode(res.body));
    }
    throw Exception(res.body);
  }

  // ==================== GET BY POST + REACTION ====================
  static Future<List<PostReactionResponse>> getByPostAndReaction(
    String postId,
    String reaction,
    String token,
  ) async {
    final res = await http.get(
      Uri.parse("$_base/post/$postId/reaction?reaction=$reaction"),
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

  // ==================== SEARCH BY COMMENT ====================
  static Future<List<PostReactionResponse>> searchByComment(
      String comment, String token) async {
    final res = await http.get(
      Uri.parse("$_base/search?comment=${Uri.encodeComponent(comment)}"),
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

  // ==================== GET ALL ====================
  static Future<List<PostReactionResponse>> getAll(String token) async {
    final res = await http.get(
      Uri.parse("$_base/all"),
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
}