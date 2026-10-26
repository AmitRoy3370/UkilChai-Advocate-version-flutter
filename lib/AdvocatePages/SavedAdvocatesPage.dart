// lib/AdvocatePages/SavedAdvocatesPage.dart
//
// Lists all bookmarked advocates for the current user.
// Reads the saved snapshots directly from SharedPreferences — no network
// calls needed for the list itself.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as BASE_URL;
import 'AdvocateDetails.dart';
import 'AdvocateDetailsModel.dart';
import 'BookmarkService.dart';

class SavedAdvocatesPage extends StatefulWidget {
  const SavedAdvocatesPage({super.key});

  @override
  State<SavedAdvocatesPage> createState() => _SavedAdvocatesPageState();
}

class _SavedAdvocatesPageState extends State<SavedAdvocatesPage> {
  bool _loading = true;
  String? _error;
  List<SavedAdvocateSnapshot> _snapshots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Tell BookmarkService which user's list to load.
      final me = await AuthService.getUserId();
      debugPrint("SavedAdvocatesPage: currentUserId = $me");
      BookmarkService.setCurrentUser(me);

      // 2. Read the index (list of IDs).
      final ids = await BookmarkService.getSavedIds();
      debugPrint("SavedAdvocatesPage: saved IDs = $ids");

      // 3. Read each snapshot individually, skipping broken ones.
      final list = <SavedAdvocateSnapshot>[];

      final prefs = await SharedPreferences.getInstance();
      final prefix = me == null || me.isEmpty
          ? null
          : '${me}_saved_advocate_';

      if (prefix == null) {
        if (!mounted) return;
        setState(() {
          _snapshots = [];
          _loading = false;
        });
        return;
      }

      for (final id in ids) {
        final raw = prefs.getString('$prefix$id');
        if (raw == null || raw.isEmpty) {
          debugPrint("SavedAdvocatesPage: missing entry for id=$id");
          continue;
        }
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          list.add(SavedAdvocateSnapshot.fromJson(json));
        } catch (e) {
          debugPrint("SavedAdvocatesPage: skipping corrupt entry "
              "for id=$id → $e");
        }
      }

      debugPrint("SavedAdvocatesPage: loaded ${list.length} snapshots");

      if (!mounted) return;
      setState(() {
        _snapshots = list;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint("SavedAdvocatesPage: error = $e\n$st");
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _remove(SavedAdvocateSnapshot s) async {
    if (s.id.isEmpty) return;

    try {
      await BookmarkService.remove(s.id);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _snapshots.removeWhere((x) => x.id == s.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from bookmarks'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openDetails(SavedAdvocateSnapshot s) async {
    final model = await _fetchFullModel(s);
    if (!mounted) return;

    if (model == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't open this advocate. Try again later."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdvocateDetails(advocateDetailsModel: model),
      ),
    );

    if (!mounted) return;
    _load();
  }

  /// Try several endpoint variants so we always find the advocate.
  Future<AdvocateDetailsModel?> _fetchFullModel(
    SavedAdvocateSnapshot s,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final ids = <String>{
        if (s.id.isNotEmpty) s.id,
        if (s.userId != null && s.userId!.isNotEmpty) s.userId!,
      };

      final templates = <String>[
        "${BASE_URL.Urls().baseURL}advocate/{}",
        "${BASE_URL.Urls().baseURL}advocate/findByUserId/{}",
        "${BASE_URL.Urls().baseURL}advocate/user/{}",
      ];

      for (final id in ids) {
        for (final t in templates) {
          final url = t.replaceFirst('{}', id);
          try {
            final res = await http.get(
              Uri.parse(url),
              headers: {"Authorization": "Bearer $token"},
            );
            if (res.statusCode != 200) continue;

            final decoded = jsonDecode(res.body);

            if (decoded is Map && decoded['id'] != null) {
              return AdvocateDetailsModel.fromJson(
                Map<String, dynamic>.from(decoded),
              );
            }
            if (decoded is Map && decoded['data'] is Map) {
              return AdvocateDetailsModel.fromJson(
                Map<String, dynamic>.from(decoded['data']),
              );
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Fallback: build a minimal model from the snapshot itself.
    try {
      return AdvocateDetailsModel.fromJson({
        'id': s.id,
        'userId': s.userId,
        'name': s.name,
        'fullName': s.fullName,
        'profileImageId': s.profileImageId,
        'advocateSpeciality': s.advocateSpeciality,
        'locationName': s.locationName,
        'district': s.district,
        'experience': s.experience,
      });
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Saved Advocates",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── Loading ──
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      );
    }

    // ── Error ──
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                "Couldn't load saved advocates",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    // ── Empty ──
    if (_snapshots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "No saved advocates yet",
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Bookmark advocates to see them here",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    // ── List ──
    return RefreshIndicator(
      onRefresh: _load,
      color: Colors.purple,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _snapshots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _card(_snapshots[i]),
      ),
    );
  }

  Widget _card(SavedAdvocateSnapshot s) {
    final displayName =
        (s.fullName?.isNotEmpty == true ? s.fullName : s.name) ??
            'Unknown Advocate';
    final specialty =
        s.advocateSpeciality.isNotEmpty ? s.advocateSpeciality.first : '';
    final location = s.locationName ?? '';
    final exp = s.experience ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetails(s),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(
                cachedBytes: s.profileImageBytes,
                imageId: s.profileImageId,
                radius: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    if (specialty.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        specialty,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.purple.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (location.isNotEmpty) ...[
                          Icon(Icons.location_on,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              location,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Icon(Icons.work_outline,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(
                          "$exp yrs",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Remove bookmark",
                icon: Icon(Icons.bookmark, color: Colors.red.shade400),
                onPressed: () => _remove(s),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small circular avatar. Prefers cached base64 bytes; falls back to
/// fetching the image from the download endpoint.
class _Avatar extends StatelessWidget {
  final Uint8List? cachedBytes;
  final String? imageId;
  final double radius;
  const _Avatar({
    required this.cachedBytes,
    required this.imageId,
    this.radius = 32,
  });

  Future<Uint8List?> _fetchRemote() async {
    if (imageId == null || imageId!.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final res = await http.get(
        Uri.parse("${BASE_URL.Urls().baseURL}user/download/$imageId"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) return res.bodyBytes;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (cachedBytes != null && cachedBytes!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(cachedBytes!),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _fetchRemote(),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(snapshot.data!),
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.purple.shade50,
          child: Icon(
            Icons.person,
            size: radius,
            color: Colors.purple.shade300,
          ),
        );
      },
    );
  }
}