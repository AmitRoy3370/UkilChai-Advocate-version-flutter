// lib/Tin/screens/my_tin_process_control_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/center_admin_bridge.dart'; // ✅ myAdvocates + myCenterAdminId
import '../models/tin_response_dto.dart';
import '../services/tin_service.dart';
import 'tin_details_screen.dart';

class MyTinProcessControlScreen extends StatefulWidget {
  const MyTinProcessControlScreen({super.key});

  @override
  State<MyTinProcessControlScreen> createState() =>
      _MyTinProcessControlScreenState();
}

class _MyTinProcessControlScreenState
    extends State<MyTinProcessControlScreen> {
  static const Color _primaryGreen = Color(0xFF1E7A3A);

  bool _loading = true;
  String? _error;

  /// User._id (for isOwner checks)
  String _myUserId = '';

  /// CenterAdmin._id (for filtering processes)
  String _myCenterAdminId = '';

  final List<_Entry> _entries = [];
  final Map<String, String> _advocateNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _entries.clear();
      _advocateNames.clear();
    });

    try {
      // 1. Load user id from prefs
      final prefs = await SharedPreferences.getInstance();
      _myUserId = prefs.getString('userId') ?? '';
      debugPrint('🟦 [MyTinProcessControl] myUserId = $_myUserId');

      if (_myUserId.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Please log in';
        });
        return;
      }

      // 2. Resolve the CenterAdmin._id for this user
      try {
        _myCenterAdminId =
            await CenterAdminBridge.myCenterAdminId(_myUserId);
        debugPrint(
            '🟦 [MyTinProcessControl] myCenterAdminId = $_myCenterAdminId');
      } catch (e) {
        debugPrint('⚠️ Could not resolve center admin id: $e');
        setState(() {
          _loading = false;
          _error = 'You are not registered as a center admin.';
        });
        return;
      }

      // 3. Fetch ALL TIN records
      final res = await TinService.findAll();
      final allTin = TinService.parseList(res);
      debugPrint('🟦 [MyTinProcessControl] total TIN = ${allTin.length}');

      // 4. Filter: keep only those where registrationProcess.centerAdminId
      //    equals MY center admin id
      final mine = <TinResponseDTO>[];
      for (final tin in allTin) {
        final rp = tin.registrationProcess;
        debugPrint('   → tin.id=${tin.id} '
            'rp.centerAdminId=${rp?.centerAdminId} '
            'myCenterAdminId=$_myCenterAdminId');
        if (rp == null) continue;
        if (rp.centerAdminId != _myCenterAdminId) continue;
        mine.add(tin);
      }
      debugPrint('🟩 [MyTinProcessControl] mine = ${mine.length}');

      // 5. Resolve advocate names once
      try {
        final advocates = await CenterAdminBridge.myAdvocates(_myUserId);
        for (final a in advocates) {
          _advocateNames[a.id] = a.name;
        }
        debugPrint(
            '🟦 [MyTinProcessControl] loaded ${advocates.length} advocates');
      } catch (e) {
        debugPrint('⚠️ Failed to load advocates: $e');
      }

      // 6. Build entries
      for (final tin in mine) {
        final rp = tin.registrationProcess!;
        final advName = _advocateNames[rp.advocateId] ??
            (rp.advocateId.isEmpty ? '' : rp.advocateId);

        _entries.add(_Entry(tin: tin, advocateName: advName));
      }

      debugPrint('🟩 [MyTinProcessControl] entries = ${_entries.length}');

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Error: $e';
      });
    }
  }

  Future<void> _openDetails(_Entry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TinDetailsScreen(
          tin: entry.tin,
          isOwner: entry.tin.userId == _myUserId,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'My TIN Processes',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _entries.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: _primaryGreen,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, i) =>
                            _entryCard(_entries[i]),
                      ),
                    ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No TIN processes assigned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accept a TIN filing from its details page to start managing it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryCard(_Entry entry) {
    final v = entry.tin;
    final rp = v.registrationProcess!;
    final advName = entry.advocateName;

    final steps = rp.steps;
    final isApproved =
        steps.isNotEmpty && steps.last.toLowerCase().contains('approved');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetails(entry),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryGreen.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.badge_outlined,
                        color: _primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.fullName.isEmpty ? 'Untitled' : v.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phone: ${v.phone}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(isApproved),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      advName.isEmpty
                          ? 'Advocate: —'
                          : 'Advocate: $advName',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.format_list_numbered,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${steps.length} steps',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(bool approved) {
    final color = approved ? _primaryGreen : const Color(0xFFE65100);
    final label = approved ? 'Approved' : 'In Progress';
    final icon = approved ? Icons.check_circle : Icons.hourglass_empty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Entry {
  final TinResponseDTO tin;
  final String advocateName;
  _Entry({
    required this.tin,
    required this.advocateName,
  });
}