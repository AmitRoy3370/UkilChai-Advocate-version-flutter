// lib/AdvocatePages/BookmarkService.dart
//
// Per-user bookmarked advocates stored in SharedPreferences.
//
// Key layout:
//   {userId}_saved_advocate_index              -> List<String> of advocate IDs
//   {userId}_saved_advocate_{advocateId}       -> JSON snapshot of the advocate
//
// The snapshot includes the profile image as base64, so the saved list
// renders instantly without any network calls.

import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class SavedAdvocateSnapshot {
  final String id;
  final String? userId;
  final String? name;
  final String? fullName;
  final String? profileImageId;
  final List<String> advocateSpeciality;
  final String? locationName;
  final String? district;
  final int? experience;
  final Uint8List? profileImageBytes;

  SavedAdvocateSnapshot({
    required this.id,
    this.userId,
    this.name,
    this.fullName,
    this.profileImageId,
    this.advocateSpeciality = const [],
    this.locationName,
    this.district,
    this.experience,
    this.profileImageBytes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'fullName': fullName,
        'profileImageId': profileImageId,
        'advocateSpeciality': advocateSpeciality,
        'locationName': locationName,
        'district': district,
        'experience': experience,
        'profileImageBase64': profileImageBytes != null
            ? base64Encode(profileImageBytes!)
            : null,
      };

  factory SavedAdvocateSnapshot.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    final b64 = json['profileImageBase64'];
    if (b64 is String && b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } catch (_) {}
    }

    return SavedAdvocateSnapshot(
      id: (json['id'] ?? '').toString(),
      userId: json['userId']?.toString(),
      name: json['name']?.toString(),
      fullName: json['fullName']?.toString(),
      profileImageId: json['profileImageId']?.toString(),
      advocateSpeciality:
          (json['advocateSpeciality'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
      locationName: json['locationName']?.toString(),
      district: json['district']?.toString(),
      experience: json['experience'] is int
          ? json['experience'] as int
          : int.tryParse('${json['experience']}'),
      profileImageBytes: bytes,
    );
  }
}

class BookmarkService {
  /// SharedPreferences key prefix — must be set before use.
  /// It's `{userId}_saved_advocate_`.
  static String? _userPrefix;

  /// Call this once at login / app start so the service knows which user's
  /// bookmark list to load. Safe to call multiple times.
  static void setCurrentUser(String? userId) {
    if (userId == null || userId.isEmpty) {
      _userPrefix = null;
    } else {
      _userPrefix = '${userId}_saved_advocate_';
    }
  }

  static String get _indexKey {
    final p = _userPrefix;
    if (p == null) {
      throw StateError(
        'BookmarkService: current user not set. Call setCurrentUser(userId).',
      );
    }
    return '${p}index';
  }

  static String _entryKey(String advocateId) {
    final p = _userPrefix;
    if (p == null) {
      throw StateError(
        'BookmarkService: current user not set. Call setCurrentUser(userId).',
      );
    }
    return '$p$advocateId';
  }

  // ──────────────────────────────────────────────────────────────────────
  // Read
  // ──────────────────────────────────────────────────────────────────────

  /// Ordered list of advocate IDs saved by the current user.
  static Future<List<String>> getSavedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_indexKey) ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  /// The full snapshot list, in the order they were saved.
  static Future<List<SavedAdvocateSnapshot>> getSnapshots() async {
    final ids = await getSavedIds();
    if (ids.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final out = <SavedAdvocateSnapshot>[];

    for (final id in ids) {
      final raw = prefs.getString(_entryKey(id));
      if (raw == null || raw.isEmpty) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        out.add(SavedAdvocateSnapshot.fromJson(json));
      } catch (_) {
        // skip corrupt entry
      }
    }
    return out;
  }

  /// True if the given advocate is bookmarked by the current user.
  static Future<bool> isBookmarked(String advocateId) async {
    if (advocateId.isEmpty) return false;
    final ids = await getSavedIds();
    return ids.contains(advocateId);
  }

  /// Count for the current user.
  static Future<int> count() async {
    final ids = await getSavedIds();
    return ids.length;
  }

  // ──────────────────────────────────────────────────────────────────────
  // Write
  // ──────────────────────────────────────────────────────────────────────

  /// Saves the given snapshot. Overwrites if already present.
  static Future<void> add(SavedAdvocateSnapshot snapshot) async {
    if (snapshot.id.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _entryKey(snapshot.id);

    // Persist the entry itself.
    await prefs.setString(key, jsonEncode(snapshot.toJson()));

    // Update the index.
    final ids = prefs.getStringList(_indexKey) ?? <String>[];
    if (!ids.contains(snapshot.id)) {
      ids.add(snapshot.id);
      await prefs.setStringList(_indexKey, ids);
    }
  }

  /// Removes the advocate from the current user's bookmarks.
  static Future<void> remove(String advocateId) async {
    if (advocateId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entryKey(advocateId));

    final ids = prefs.getStringList(_indexKey) ?? <String>[];
    ids.remove(advocateId);
    await prefs.setStringList(_indexKey, ids);
  }

  /// Clears all saved advocates for the current user.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_indexKey) ?? <String>[];
    for (final id in ids) {
      await prefs.remove(_entryKey(id));
    }
    await prefs.remove(_indexKey);
  }
}