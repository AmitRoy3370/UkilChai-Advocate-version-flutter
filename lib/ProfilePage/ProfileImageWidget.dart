import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as baseURL;
import 'dart:convert';
import 'dart:io';

// NOTE: To make this work, add the following to your AuthService.dart file:
// static ValueNotifier<String?> userIdNotifier = ValueNotifier(null);
// Then, in your login function, after setting the userId (e.g., in shared preferences), add:
// AuthService.userIdNotifier.value = userId;
// This will notify all ProfileImageWidget instances to reload the image after login.

class ProfileImageWidget extends StatefulWidget {
  final double radius;

  const ProfileImageWidget({super.key, this.radius = 45});

  @override
  State<ProfileImageWidget> createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  Uint8List? imageBytes;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    print("initState called - starting to load profile image");
    loadProfileImage();
    AuthService.userIdNotifier.addListener(_reload);
  }

  void _reload() {
    print("Auth changed - reloading profile image");
    if (imageBytes == null && !loading) {
      loadProfileImage();
    }
  }

  @override
  void dispose() {
    AuthService.userIdNotifier.removeListener(_reload);
    super.dispose();
  }

  Future<void> loadProfileImage() async {
    print("loadProfileImage function started");
    try {
      final token = await AuthService.getToken();
      final userId = await AuthService.getUserId();

      print("token for loading image time :- $token and userId :- $userId");

      if (token == null || userId == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final userSearchResponse = "${baseURL.Urls().baseURL}user/search?userId=$userId";

      final userSearchResponseUri = Uri.parse(userSearchResponse);

      final userSearchResponseResponse = await http.get(
        userSearchResponseUri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      print("user search result :- ${userSearchResponseResponse.statusCode}");
      print("user search body :- ${userSearchResponseResponse.body}");

      if (userSearchResponseResponse.statusCode != 200) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final responseBody = jsonDecode(userSearchResponseResponse.body);
      print("user search decoded body :- $responseBody");

      final profileImageId = responseBody["profileImageId"];

      print("profileImageId :- $profileImageId");

      if (profileImageId == null || profileImageId.toString().isEmpty) {
        if (mounted) setState(() => loading = false);
        return;
      }

      // Trying the backend-provided endpoint first (/download/{imageId})
      String downloadUrl = "${baseURL.Urls().baseURL}download/$profileImageId";
      print("Trying download URL: $downloadUrl");

      var response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          "Accept": "image/*,application/octet-stream",
          "Authorization": "Bearer $token"
        },
      );

      print("get profile image response for /download :- ${response.statusCode}");
      print("response body (if not 200): ${response.statusCode != 200 ? response.body : 'Binary data'}");
      print("response bytes length: ${response.bodyBytes.length}");

      // If failed, try the alternative /user/download
      if (response.statusCode != 200) {
        downloadUrl = "${baseURL.Urls().baseURL}user/download/$profileImageId";
        print("Fallback to alternative URL: $downloadUrl");
        response = await http.get(
          Uri.parse(downloadUrl),
          headers: {
            "Accept": "image/*,application/octet-stream",
            "Authorization": "Bearer $token"
          },
        );
        print("get profile image response for /user/download :- ${response.statusCode}");
        print("response body (if not 200): ${response.statusCode != 200 ? response.body : 'Binary data'}");
        print("response bytes length: ${response.bodyBytes.length}");
      }

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // Simple check if bytes resemble image data
        bool isLikelyImage = response.bodyBytes.length > 4 &&
            ((response.bodyBytes[0] == 0xFF && response.bodyBytes[1] == 0xD8) || // JPEG
                (response.bodyBytes[0] == 0x89 && response.bodyBytes[1] == 0x50 && response.bodyBytes[2] == 0x4E && response.bodyBytes[3] == 0x47)); // PNG
        if (isLikelyImage) {
          print("Valid image bytes detected");
          if (mounted) {
            setState(() {
              imageBytes = response.bodyBytes;
              loading = false;
            });
          }
        } else {
          print("Bytes received but not a valid image format");
          if (mounted) setState(() => loading = false);
        }
      } else {
        if (mounted) setState(() => loading = false);
      }
    } catch (e) {
      print("Error in loadProfileImage: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print("build called - loading: $loading, hasImage: ${imageBytes != null}");
    if (loading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.grey[800],
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: imageBytes != null ? MemoryImage(imageBytes!) : null,
      child: imageBytes == null
          ? Icon(
        Icons.person,
        size: widget.radius * 1.2,
        color: Colors.grey.shade700,
      )
          : null,
    );
  }
}