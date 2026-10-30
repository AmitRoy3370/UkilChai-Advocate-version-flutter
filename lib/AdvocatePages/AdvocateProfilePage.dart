// lib/AdvocatePages/AdvocateProfilePage.dart
//
// Advocate-side profile page. Mirrors the visual design of the user panel
// ProfileHubPage, but pulls data from advocate services and includes
// working-experience, additional-info and advocate-documents sections.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../Auth/AuthService.dart';
import '../Utils/BaseURL.dart' as BASEURL;

import 'advocate_service.dart';
import 'advocate_working_experience_service.dart';
import 'advocate_additional_info_service.dart';
import 'advocate_documents_service.dart';

import 'AdvocateDetailsModel.dart';
import 'advocate_working_experience_model.dart';
import 'advocate_additional_info_model.dart';
import 'advocate_documents_model.dart';

import '../CaseRelatedPages/AttachmentViewer.dart'; // CaseAttachmentView
import '../ProfilePage/UpdateProfile.dart'; // ✅ UpdateProfile — no-arg constructor

// ─── Design tokens (same palette as user panel) ─────────────────────────────
class _C {
  static const forest      = Color(0xFF1A3C2B);
  static const mid         = Color(0xFF2D6A4F);
  static const sage        = Color(0xFF52B788);
  static const frost       = Color(0xFFF0F7F3);
  static const ivory       = Color(0xFFFAFAF8);
  static const ink         = Color(0xFF111B17);
  static const slate       = Color(0xFF4B5563);
  static const mist        = Color(0xFF9CA3AF);
  static const line        = Color(0xFFE4EBE7);
  static const danger      = Color(0xFFDC2626);
  static const dangerPale  = Color(0xFFFEF2F2);
  static const warn        = Color(0xFF92400E);
  static const warnPale    = Color(0xFFFFFBEB);
  static const success     = Color(0xFF065F46);
  static const successPale = Color(0xFFECFDF5);
}

// ═════════════════════════════════════════════════════════════════════════════
// Root page
// ═════════════════════════════════════════════════════════════════════════════

class AdvocateProfilePage extends StatefulWidget {
  final String? advocateId; // optional — defaults to the logged-in user's advocate
  const AdvocateProfilePage({super.key, this.advocateId});

  @override
  State<AdvocateProfilePage> createState() => _AdvocateProfilePageState();
}

class _AdvocateProfilePageState extends State<AdvocateProfilePage> {
  String _screen = "profile";

  // Master data
  AdvocateDetailsModel? _advocate;
  AdvocateWorkingExperience? _experience;
  AdvocateAdditionalInfo? _additionalInfo;
  AdvocateDocuments? _documents;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadEverything() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Resolve advocateId
      String? advocateId = widget.advocateId;
      AdvocateDetailsModel? adv;
      if (advocateId == null || advocateId.isEmpty) {
        final userId = await AuthService.getUserId();
        if (userId == null || userId.isEmpty) {
          throw Exception("Not logged in — cannot load advocate profile.");
        }
        adv = await AdvocateService.findByUserId(userId);
        advocateId = adv.id;
      }

      if (advocateId == null || advocateId.isEmpty) {
        throw Exception("No advocate record found for this user.");
      }

      final resolvedId = advocateId;

      // 2. Fetch all four payloads in parallel
      final results = await Future.wait<dynamic>([
        adv != null
            ? Future<AdvocateDetailsModel>.value(adv)
            : AdvocateService.findById(resolvedId),
        _safeFetch(() =>
            AdvocateWorkingExperienceService.findByAdvocateId(resolvedId)),
        _safeFetch(() =>
            AdvocateAdditionalInfoService.findByAdvocateId(resolvedId)),
        _safeFetch(() =>
            AdvocateDocumentsService.findByAdvocateId(resolvedId)),
      ]);

      if (!mounted) return;
      setState(() {
        _advocate       = results[0] as AdvocateDetailsModel;
        _experience     = results[1] as AdvocateWorkingExperience?;
        _additionalInfo = results[2] as AdvocateAdditionalInfo?;
        _documents      = results[3] as AdvocateDocuments?;
        _loading        = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString();
        _loading = false;
      });
    }
  }

  Future<T?> _safeFetch<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  // ─── Navigation helpers ───────────────────────────────────────────────────

  void _setScreen(String s) => setState(() => _screen = s);

  Future<void> _openEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpdateProfile()),
    );
    await _loadEverything();
  }

  Future<void> _openAttachment(String id) async {
    final token = await AuthService.getToken() ?? '';
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: _C.forest,
            foregroundColor: Colors.white,
            title: const Text("Attachment"),
          ),
          body: CaseAttachmentView(
            attachmentId: id,
            jwtToken: token,
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This will permanently remove your advocate account. Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("userId");
      final token  = prefs.getString("jwt_token");
      if (userId == null || token == null) return;

      final resp = await http.delete(
        Uri.parse("${BASEURL.Urls().baseURL}user/delete/$userId?tryingToDelete=$userId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (!mounted) return;
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(resp.body)));
        await AuthService.logout();
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account deletion failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Delete error: $e")));
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Build
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.ivory,
      body: SafeArea(child: _buildScreen()),
    );
  }

  Widget _buildScreen() {
    switch (_screen) {
      case "profile":       return _buildProfileMain();
      case "personalInfo":  return _buildPersonalInfo();
      case "contactInfo":   return _buildContactInfo();
      case "workingExp":    return _buildWorkingExperience();
      case "additionalInfo":return _buildAdditionalInfo();
      case "documents":     return _buildDocuments();
      case "specialities":  return _buildSpecialities();
      default:              return _buildProfileMain();
    }
  }

  // ─── Main profile ─────────────────────────────────────────────────────────

  Widget _buildProfileMain() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.mid));
    }
    if (_error != null) {
      return _buildErrorState(_error!, _loadEverything);
    }
    final a = _advocate!;
    final displayName = _displayName(a);
    final initials    = _initials(displayName);

    return RefreshIndicator(
      color: _C.mid,
      onRefresh: _loadEverything,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_C.forest, _C.mid],
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    "Advocate Profile",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openEditProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "✏️ Edit",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Avatar card
            Transform.translate(
              offset: const Offset(0, -46),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x211A3C2B),
                      blurRadius: 30,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _SealAvatar(initials: initials, size: 60, ring: _C.mid),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: _C.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "⚖️ Advocate",
                            style: const TextStyle(
                                fontSize: 12, color: _C.mid),
                          ),
                          if ((a.district ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              "📍 ${a.district}",
                              style: const TextStyle(
                                  fontSize: 11, color: _C.mist),
                            ),
                          ],
                          if ((a.email ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              "📧 ${a.email}",
                              style: const TextStyle(
                                  fontSize: 11, color: _C.mist),
                            ),
                          ],
                          if (a.experience != null) ...[
                            const SizedBox(height: 6),
                            _Pill(
                              text: "${a.experience} yrs experience",
                              color: _C.frost,
                              fg: _C.mid,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _statCard("⭐", a.rating.toStringAsFixed(1), "Rating"),
                  const SizedBox(width: 10),
                  _statCard(
                      "🧑‍⚖️", "${a.advocateSpeciality.length}", "Specialities"),
                  const SizedBox(width: 10),
                  _statCard("🎓", "${a.degrees.length}", "Degrees"),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Account
            _sectionLabel("Account"),
            _menuGroup([
              _MenuRow(
                icon: "👤",
                label: "Personal Information",
                sub: "Name, License, Degrees",
                onTap: () => _setScreen("personalInfo"),
              ),
              _MenuRow(
                icon: "📱",
                label: "Contact Details",
                sub: "Email, Phone, Location",
                onTap: () => _setScreen("contactInfo"),
              ),
              _MenuRow(
                icon: "⚖️",
                label: "Specialities & Practice",
                sub: a.advocateSpeciality.isEmpty
                    ? "None added"
                    : a.advocateSpeciality.join(", "),
                onTap: () => _setScreen("specialities"),
              ),
              // 👇 ADDED CV SECTION HERE
              _MenuRow(
                icon: "📄",
                label: "Curriculum Vitae (CV)",
                sub: (a.cvHexKey ?? '').isNotEmpty ? "View CV" : "No CV uploaded",
                onTap: (a.cvHexKey ?? '').isNotEmpty
                    ? () => _openAttachment(a.cvHexKey!)
                    : null,
              ),
            ]),

            // Professional
            _sectionLabel("Professional"),
            _menuGroup([
              _MenuRow(
                icon: "💼",
                label: "Working Experience",
                sub: _experience == null
                    ? "Not added yet"
                    : (_experience!.currentChemberName.isNotEmpty
                        ? _experience!.currentChemberName
                        : "View details"),
                onTap: () => _setScreen("workingExp"),
              ),
              _MenuRow(
                icon: "🪪",
                label: "Additional Information",
                sub: _additionalInfo == null
                    ? "Not added yet"
                    : "NID, DOB, Address",
                onTap: () => _setScreen("additionalInfo"),
              ),
              _MenuRow(
                icon: "📂",
                label: "Documents",
                sub: _documents == null || _documents!.attachments.isEmpty
                    ? "None uploaded"
                    : "${_documents!.attachments.length} attachments",
                onTap: () => _setScreen("documents"),
              ),
            ]),

            // Danger zone
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.line),
                ),
                child: Column(
                  children: [
                    _MenuRow(
                      icon: "🚪",
                      label: "Logout",
                      danger: true,
                      onTap: _logout,
                    ),
                    _MenuRow(
                      icon: "🗑️",
                      label: "Delete Account",
                      sub: "Permanently remove your account",
                      danger: true,
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Personal Information ─────────────────────────────────────────────────

  Widget _buildPersonalInfo() {
    final a = _advocate!;
    return Column(
      children: [
        _BackHeader(
          title: "Personal Information",
          onBack: () => _setScreen("profile"),
          action: GestureDetector(
            onTap: _openEditProfile,
            child: const Text(
              "Edit",
              style: TextStyle(
                  color: _C.mid,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _infoCard("Basic Information", [
                  _InfoRow(label: "Full Name", value: _displayName(a), icon: "👤"),
                  _InfoRow(label: "Name", value: a.name, icon: "🏷"),
                  _InfoRow(label: "License Key", value: a.licenseKey, icon: "🪪"),
                  _InfoRow(label: "Experience", value: a.experience?.toString(), icon: "📅"),
                  _InfoRow(label: "Rating", value: a.rating.toStringAsFixed(1), icon: "⭐"),
                  _InfoRow(label: "District", value: a.district, icon: "📍"),
                ]),
                const SizedBox(height: 14),
                _infoCard("Degrees", [
                  if (a.degrees.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      child: Text("No degrees added",
                          style: TextStyle(color: _C.mist, fontSize: 13)),
                    )
                  else
                    ...a.degrees.map(
                      (d) => _InfoRow(label: "Degree", value: d, icon: "🎓"),
                    ),
                ]),
                const SizedBox(height: 14),
                _infoCard("Working Experience (Legacy)", [
                  if (a.workingExperiences.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      child: Text("No legacy entries",
                          style: TextStyle(color: _C.mist, fontSize: 13)),
                    )
                  else
                    ...a.workingExperiences.map(
                      (w) => _InfoRow(label: "Entry", value: w, icon: "💼"),
                    ),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openEditProfile,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Edit Advocate Profile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Contact Info ─────────────────────────────────────────────────────────

  Widget _buildContactInfo() {
    final a = _advocate!;
    final lat = a.lattitude != null ? a.lattitude!.toStringAsFixed(5) : '';
    final lng = a.longitude != null ? a.longitude!.toStringAsFixed(5) : '';

    return Column(
      children: [
        _BackHeader(
          title: "Contact Details",
          onBack: () => _setScreen("profile"),
          action: GestureDetector(
            onTap: _openEditProfile,
            child: const Text(
              "Edit",
              style: TextStyle(
                  color: _C.mid,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: _infoCard("Contact Information", [
              _InfoRow(label: "Email", value: a.email, icon: "📧"),
              _InfoRow(label: "Phone", value: a.phone, icon: "📱"),
              _InfoRow(label: "Location", value: a.locationName, icon: "📍"),
              _InfoRow(label: "District", value: a.district, icon: "🏙"),
              _InfoRow(label: "Latitude", value: lat, icon: "🗺"),
              _InfoRow(label: "Longitude", value: lng, icon: "🗺"),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── Specialities ─────────────────────────────────────────────────────────

  Widget _buildSpecialities() {
    final a = _advocate!;
    return Column(
      children: [
        _BackHeader(
          title: "Specialities & Practice",
          onBack: () => _setScreen("profile"),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (a.advocateSpeciality.isEmpty)
                  _emptyCard("No specialities added yet.")
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: a.advocateSpeciality
                        .map((s) => _Pill(
                              text: s.replaceAll("_", " "),
                              color: _C.frost,
                              fg: _C.mid,
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 20),
                _infoCard("Practice Summary", [
                  _InfoRow(
                      label: "Years Practising",
                      value: a.experience?.toString(),
                      icon: "📅"),
                  _InfoRow(
                      label: "Rating",
                      value: a.rating.toStringAsFixed(1),
                      icon: "⭐"),
                  _InfoRow(
                      label: "District",
                      value: a.district,
                      icon: "📍"),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Working Experience ───────────────────────────────────────────────────

  Widget _buildWorkingExperience() {
    final e = _experience;
    return Column(
      children: [
        _BackHeader(
          title: "Working Experience",
          onBack: () => _setScreen("profile"),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: e == null
                ? _emptyCard(
                    "No working experience added yet.\nUse the edit screen to add one.",
                  )
                : _infoCard("Professional Details", [
                    _InfoRow(
                        label: "Current Chamber",
                        value: e.currentChemberName,
                        icon: "🏛"),
                    _InfoRow(
                        label: "Bar Association",
                        value: e.barAssociation,
                        icon: "⚖️"),
                    _InfoRow(
                        label: "Bar Council Enrolment",
                        value: e.barControllEnrolment,
                        icon: "🪪"),
                    _InfoRow(
                        label: "Enrollment Date",
                        value: e.enrollmentDate,
                        icon: "📅"),
                    _InfoRow(
                        label: "Practising Coat",
                        value: e.practicingCoat,
                        icon: "🧥"),
                    _InfoRow(
                        label: "Primary Practice",
                        value: e.primaryPractice,
                        icon: "🎯"),
                    _InfoRow(
                        label: "Years of Legal Practice",
                        value: e.yearOfLegalPractice.toString(),
                        icon: "📊"),
                    _InfoRow(
                        label: "Professional Experience",
                        value: e.professionalExperience.toString(),
                        icon: "💼"),
                  ]),
          ),
        ),
      ],
    );
  }

  // ─── Additional Info ──────────────────────────────────────────────────────

  Widget _buildAdditionalInfo() {
    final i = _additionalInfo;
    return Column(
      children: [
        _BackHeader(
          title: "Additional Information",
          onBack: () => _setScreen("profile"),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: i == null
                ? _emptyCard(
                    "No additional info added yet.\nUse the edit screen to add one.",
                  )
                : _infoCard("Personal Details", [
                    _InfoRow(
                        label: "Permanent Address",
                        value: i.parmanentAdress,
                        icon: "🏠"),
                    _InfoRow(
                        label: "City / Upazila",
                        value: i.cityOfUpozila,
                        icon: "🏙"),
                    _InfoRow(
                        label: "NID Number",
                        value: i.nidNumber,
                        icon: "🪪"),
                    _InfoRow(
                        label: "Date of Birth",
                        value: i.dateOfBirth,
                        icon: "🎂"),
                    _InfoRow(
                        label: "WhatsApp",
                        value: i.whatsAppNumber,
                        icon: "💬"),
                  ]),
          ),
        ),
      ],
    );
  }

  // ─── Documents ────────────────────────────────────────────────────────────

  Widget _buildDocuments() {
    final d = _documents;
    return Column(
      children: [
        _BackHeader(
          title: "Documents",
          onBack: () => _setScreen("profile"),
        ),
        Expanded(
          child: d == null || d.attachments.isEmpty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: _emptyCard(
                    "No documents uploaded yet.\nUpload documents from the edit screen.",
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: d.attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final attId = d.attachments[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.line),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _C.frost,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child:
                              const Text("📄", style: TextStyle(fontSize: 20)),
                        ),
                        title: Text(
                          "Document ${i + 1}",
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        subtitle: Text(
                          attId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: _C.mist),
                        ),
                        trailing: const Icon(Icons.open_in_new,
                            size: 18, color: _C.mid),
                        onTap: () => _openAttachment(attId),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Small building blocks ────────────────────────────────────────────────

  String _displayName(AdvocateDetailsModel a) {
    if ((a.fullName ?? '').trim().isNotEmpty) return a.fullName!.trim();
    if ((a.name ?? '').trim().isNotEmpty) return a.name!.trim();
    return 'Advocate';
  }

  String _initials(String name) {
    final src = name.trim();
    if (src.isEmpty) return '?';
    final parts = src.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _C.mist,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _menuGroup(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.line),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _statCard(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.line),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: _C.ink,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: _C.mist),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: _C.frost,
              border: Border(bottom: BorderSide(color: _C.line)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _C.ink,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.line),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: _C.mist),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: _C.danger),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.slate, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.forest,
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Reusable widgets (ported from user panel)
// ═════════════════════════════════════════════════════════════════════════════

class _SealAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color ring;
  const _SealAvatar({
    required this.initials,
    this.size = 44,
    this.ring = _C.mid,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size + 8,
            height: size + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring.withOpacity(0.6), width: 1.5),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ring.withOpacity(0.15), ring.withOpacity(0.30)],
              ),
              border: Border.all(color: ring, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: size * 0.33,
                color: ring,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color fg;
  const _Pill({required this.text, required this.color, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? action;
  const _BackHeader({
    required this.title,
    required this.onBack,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.arrow_back, size: 22, color: _C.forest),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _C.ink,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final String? icon;
  const _InfoRow({required this.label, this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final raw = (value ?? '').trim();
    final displayValue = raw.isEmpty ? '—' : raw;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _C.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _C.mist),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _C.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String icon;
  final String label;
  final String? sub;
  final bool danger;
  final VoidCallback? onTap;
  const _MenuRow({
    required this.icon,
    required this.label,
    this.sub,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _C.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: danger ? _C.dangerPale : _C.frost,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: danger ? _C.danger : _C.ink,
                    ),
                  ),
                  if (sub != null && sub!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _C.mist,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!danger)
              const Icon(Icons.chevron_right, size: 18, color: _C.mist),
          ],
        ),
      ),
    );
  }
}