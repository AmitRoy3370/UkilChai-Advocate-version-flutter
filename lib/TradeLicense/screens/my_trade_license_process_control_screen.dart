// lib/TradeLicense/screens/my_trade_license_process_control_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Vat/service/center_admin_bridge.dart'; // ✅ for AdvocateBrief
import '../models/trade_license_registration_process_model.dart';
import '../models/trade_license_response_dto.dart';
import '../services/trade_license_registration_process_service.dart';
import '../services/trade_license_service.dart';
import 'trade_license_details_screen.dart';

class MyTradeLicenseProcessControlScreen extends StatefulWidget {
  const MyTradeLicenseProcessControlScreen({super.key});

  @override
  State<MyTradeLicenseProcessControlScreen> createState() =>
      _MyTradeLicenseProcessControlScreenState();
}

class _MyTradeLicenseProcessControlScreenState
    extends State<MyTradeLicenseProcessControlScreen> {
  static const Color _primaryGreen = Color(0xFF1E7A3A);

  bool _loading = true;
  String? _error;
  String _myUserId = '';
  final List<_Entry> _entries = [];

  /// ✅ Cache advocateId -> advocateName (from CenterAdminBridge)
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
      final prefs = await SharedPreferences.getInstance();
      _myUserId = prefs.getString('userId') ?? '';
      debugPrint('🟦 [MyTLProcessControl] myUserId = $_myUserId');

      if (_myUserId.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Please log in';
        });
        return;
      }

      // 1. Fetch processes for this user
      final res =
          await TradeLicenseRegistrationProcessService.findByUserId(
              _myUserId);
      final procs =
          TradeLicenseRegistrationProcessService.parseList(res);
      debugPrint('🟦 [MyTLProcessControl] procs = ${procs.length}');

      // 2. Strict client filter
      final mine = procs.where((p) => p.userId == _myUserId).toList();

      // 3. Resolve advocate names once
      try {
        final advocates = await CenterAdminBridge.myAdvocates(_myUserId);
        for (final a in advocates) {
          _advocateNames[a.id] = a.name;
        }
        debugPrint(
            '🟦 [MyTLProcessControl] loaded ${advocates.length} advocates');
      } catch (e) {
        debugPrint('⚠️ Failed to load advocates: $e');
      }

      // 4. Resolve each TL record
      for (final p in mine) {
        try {
          final res2 = await TradeLicenseService.findById(p.tradeLicenseId);
          final tl = TradeLicenseService.parseSingle(res2);
          if (tl == null) continue;

          final advName = _advocateNames[p.advocateId] ??
              (p.advocateId.isEmpty ? '' : p.advocateId);

          _entries.add(_Entry(
            process: p,
            license: tl,
            advocateName: advName,
          ));
        } catch (e) {
          debugPrint(
              '⚠️ Failed to load TL ${p.tradeLicenseId} for process ${p.id}: $e');
        }
      }

      debugPrint('🟩 [MyTLProcessControl] entries = ${_entries.length}');

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
        builder: (_) => TradeLicenseDetailsScreen(
          license: entry.license,
          isOwner: entry.license.userId == _myUserId,
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
          'My Trade License Processes',
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
              'No Trade License processes assigned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accept a Trade License filing from its details page to start managing it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryCard(_Entry entry) {
    final v = entry.license;
    final p = entry.process;
    final isApproved = p.status;
    final advName = entry.advocateName;

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
                    child: const Icon(Icons.store,
                        color: _primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.buisnessName.isEmpty
                              ? 'Untitled'
                              : v.buisnessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Type: ${v.buisnessType}',
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
                    '${p.steps.length} steps',
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
  final TradeLicenseRegistrationProcessModel process;
  final TradeLicenseResponseDTO license;
  final String advocateName;
  _Entry({
    required this.process,
    required this.license,
    required this.advocateName,
  });
}