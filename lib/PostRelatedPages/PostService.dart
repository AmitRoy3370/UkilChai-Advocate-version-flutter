import 'dart:convert';
import 'dart:io';
import '../PostRelatedPages/post_response.dart';
import 'package:http/http.dart' as http;
import './AdvocatePost.dart';
import '../Utils/BaseURL.dart' as BASE_URL;

class PostService {
  // -------------------------------------------------
  // 1. UPLOAD POST (with optional file)
  // -------------------------------------------------
  static Future<AdvocatePost> uploadPost({
    required String userId,
    required String advocateId,
    required String postContent,
    required String postType,
    File? file,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${BASE_URL.Urls().baseURL}advocate/posts/upload/$userId"),
      );

      // Headers
      request.headers['Authorization'] = 'Bearer $token';

      // Fields
      request.fields['advocateId'] = advocateId;
      request.fields['postContent'] = postContent;
      request.fields['postType'] = postType;

      // File attachment (optional)
      if (file != null) {
        var multipartFile = await http.MultipartFile.fromPath(
          'file',
          file.path,
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();

      if (response.statusCode == 201) {
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);
        return AdvocatePost.fromJson(jsonData);
      } else {
        var errorData = await response.stream.bytesToString();
        throw Exception(errorData);
      }
    } catch (e) {
      throw Exception('Failed to upload post: $e');
    }
  }

  // -------------------------------------------------
  // 2. SEE ALL POSTS
  // -------------------------------------------------
  static Future<List<PostResponse>> fetchAllPosts(String token) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}advocate/posts/all"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load posts: ${res.body}");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => PostResponse.fromJson(e)).toList();
  }

  // -------------------------------------------------
  // 3. FIND BY ADVOCATE ID
  // -------------------------------------------------
  static Future<List<PostResponse>> fetchSpecificAdvocatesPosts(
    String? advocateId,
    String? token,
 ) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate/posts/advocate/$advocateId",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load posts: ${res.body}");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => PostResponse.fromJson(e)).toList();
  }

  // -------------------------------------------------
  // 4. FIND BY POST TYPE
  // -------------------------------------------------
  static Future<List<PostResponse>> fetchPostsByType({
    required String postType,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate/posts/type/$postType",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load posts: ${res.body}");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => PostResponse.fromJson(e)).toList();
  }

  // -------------------------------------------------
  // 5. FIND BY ADVOCATE ID + POST TYPE (FILTER)
  // -------------------------------------------------
  static Future<List<PostResponse>> filterPostsByAdvocateAndType({
    required String advocateId,
    required String postType,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate/posts/filter?advocateId=$advocateId&postType=$postType",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load posts: ${res.body}");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => PostResponse.fromJson(e)).toList();
  }

  // -------------------------------------------------
  // 6. SEARCH BY POST CONTENT
  // -------------------------------------------------
  static Future<List<PostResponse>> searchPosts({
    required String keyword,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate/posts/search?keyword=$keyword",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to search posts: ${res.body}");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => PostResponse.fromJson(e)).toList();
  }

  // -------------------------------------------------
  // 7. LATEST POSTS
  // -------------------------------------------------
  static Future<List<PostResponse>> fetchLatestPosts(String token) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}advocate/posts/latest"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load latest posts: ${res.body}");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => PostResponse.fromJson(e)).toList();
  }

  // -------------------------------------------------
  // 8. POSTS WITH ATTACHMENTS
  // -------------------------------------------------
  static Future<List<PostResponse>> fetchPostsWithAttachments(String token, String attachments) async {
    final res = await http.get(
      Uri.parse("${BASE_URL.Urls().baseURL}advocate/posts/attachments"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load posts with attachments: ${res.body}");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => PostResponse.fromJson(e)).toList();
  }

  // -------------------------------------------------
  // 9. FIND POST BY ID
  // -------------------------------------------------
  static Future<PostResponse> findPostById({
    required String postId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse(
        "${BASE_URL.Urls().baseURL}advocate/posts/findByPostId?postId=$postId",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to find post: ${res.body}");
    }

    final data = jsonDecode(res.body);
    return PostResponse.fromJson(data);
  }

  // -------------------------------------------------
  // 10. UPDATE POST
  // -------------------------------------------------
  static Future<AdvocatePost> updatePost({
    required String postId,
    required String userId,
    required String advocateId,
    String? postContent,
    required String postType,
    String? attachmentId,
    File? file,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse("${BASE_URL.Urls().baseURL}advocate/posts/update/$postId/$userId"),
      );

      // Headers
      request.headers['Authorization'] = 'Bearer $token';

      // Fields (all fields are required except file)
      request.fields['advocateId'] = advocateId;
      if (postContent != null) {
        request.fields['postContent'] = postContent;
      }
      request.fields['postType'] = postType;
      if (attachmentId != null) {
        request.fields['attachmentId'] = attachmentId;
      }

      // File attachment (optional)
      if (file != null) {
        var multipartFile = await http.MultipartFile.fromPath(
          'file',
          file.path,
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);
        return AdvocatePost.fromJson(jsonData);
      } else {
        var errorData = await response.stream.bytesToString();
        throw Exception(errorData);
      }
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  // -------------------------------------------------
  // 11. DELETE POST
  // -------------------------------------------------
  static Future<bool> deletePost({
    required String postId,
    required String userId,
    required String token,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse(
          "${BASE_URL.Urls().baseURL}advocate/posts/delete/$postId/$userId",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final responseData = jsonDecode(res.body);
        // Response format: "Deleted = true" or "Deleted = false"
        return responseData.toString().contains('true');
      } else {
        throw Exception("Failed to delete post: ${res.body}");
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }


}