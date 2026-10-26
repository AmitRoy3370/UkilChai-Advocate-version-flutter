// lib/vat/screens/my_vat_process_control_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vat_registration_process_model.dart';
import '../models/vat_response_model.dart';
import '../service/vat_registration_process_service.dart';
import '../service/vat_service.dart';
import '../service/center_admin_bridge.dart'; // ✅ for AdvocateBrief
import 'vat_details_page.dart';

class MyVatProcessControlPage extends StatefulWidget {
  const MyVatProcessControlPage({super.key});

  @override
  State<MyVatProcessControlPage> createState() =>
      _MyVatProcessControlPageState();
}

class _MyVatProcessControlPageState extends State<MyVatProcessControlPage> {
  static const Color _primaryBlue = Color(0xFF1565C0);

  bool _loading = true;
  String? _error;
  String _myUserId = '';
  final List<_Entry> _entries = [];

  /// ✅ Cache: advocateId -> advocateName (resolved via CenterAdminBridge)
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
      debugPrint('🟦 [MyVatProcessControl] myUserId = $_myUserId');

      if (_myUserId.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Please log in';
        });
        return;
      }

      // 1. Load all processes for this user (client double-check too)
      final procs =
          await VatRegistrationProcessService.findByUserId(_myUserId);
      debugPrint('🟦 [MyVatProcessControl] procs = ${procs.length}');

      final mine = procs.where((p) => p.userId == _myUserId).toList();

      // 2. Resolve advocate names via CenterAdminBridge (cached once)
      try {
        final advocates =
            await CenterAdminBridge.myAdvocates(_myUserId);
        for (final a in advocates) {
          _advocateNames[a.id] = a.name;
        }
        debugPrint(
            '🟦 [MyVatProcessControl] loaded ${advocates.length} advocates');
      } catch (e) {
        debugPrint('⚠️ Failed to load advocates: $e');
      }

      // 3. For each process, resolve the VAT record + advocate name
      for (final p in mine) {
        try {
          final vat = await VatService.findById(p.vatId);

          final advName = _advocateNames[p.advocateId] ??
              (p.advocateId.isEmpty ? '' : p.advocateId);

          _entries.add(_Entry(
            process: p,
            vat: vat,
            advocateName: advName,
          ));
        } catch (e) {
          debugPrint(
              '⚠️ Failed to load VAT ${p.vatId} for process ${p.id}: $e');
        }
      }

      debugPrint('🟩 [MyVatProcessControl] entries = ${_entries.length}');

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
        builder: (_) => VatDetailsPage(
          vat: entry.vat,
          currentUserId: _myUserId,
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
          'My VAT Processes',
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
                      color: _primaryBlue,
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
                  backgroundColor: _primaryBlue),
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
              'No VAT processes assigned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accept a VAT filing from its details page to start managing it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryCard(_Entry entry) {
    final v = entry.vat;
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
                      color: _primaryBlue.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.receipt_long,
                        color: _primaryBlue, size: 24),
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
                          'TIN: ${v.tinNo}',
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
                      // ✅ Use the resolved advocate name from the bridge
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
    final color = approved ? _primaryBlue : const Color(0xFFE65100);
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

/// ✅ Now carries the resolved advocate name (looked up via CenterAdminBridge)
class _Entry {
  final VatRegistrationProcessModel process;
  final VatResponseModel vat;
  final String advocateName;

  _Entry({
    required this.process,
    required this.vat,
    required this.advocateName,
  });
}