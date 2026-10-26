// lib/Auth/AuthGate.dart
//
// Central place to check "am I logged in?" and "am I an advocate?".
// Also exposes a reusable push-or-login helper used everywhere.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AuthService.dart';
import '../LogInPage/LogIn.dart';

class AuthGate {
  /// Returns (userId, token) or (null, null) if not logged in.
  static Future<({String? userId, String? token})> current() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('jwt_token');
    if (userId == null || userId.isEmpty || token == null || token.isEmpty) {
      return (userId: null, token: null);
    }
    return (userId: userId, token: token);
  }

  static Future<bool> isLoggedIn() async {
    final c = await current();
    return c.userId != null && c.token != null;
  }

  /// Reads 'advocateId' from SharedPreferences (set at login time if the user
  /// is an advocate). Returns null if not an advocate.
  static Future<String?> advocateId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = (prefs.getString('advocateId') ?? '').trim();
    return id.isEmpty ? null : id;
  }

  static Future<bool> isAdvocate() async {
    final id = await advocateId();
    return id != null;
  }

  /// If not logged in → push LogIn, return false.
  /// If logged in → push [builder] destination, return true.
  /// Accepts a RouteObserver-friendly builder so users land back here.
  static Future<bool> pushOrLogin(
    BuildContext context, {
    required Widget Function() builder,
    bool requireAdvocate = false,
  }) async {
    final c = await current();
    if (c.userId == null || c.token == null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LogIn()),
      );
      // If they logged in successfully, retry the navigation.
      if (result == true && context.mounted) {
        return pushOrLogin(
          context,
          builder: builder,
          requireAdvocate: requireAdvocate,
        );
      }
      return false;
    }

    if (requireAdvocate) {
      final advId = await advocateId();
      if (advId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "You're not registered as an advocate. Please register first."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    }

    if (!context.mounted) return false;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
    return true;
  }
}