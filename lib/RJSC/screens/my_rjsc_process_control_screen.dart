// lib/RJSC/screens/my_rjsc_process_control_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Auth/AuthService.dart';
import '../models/rjsc_response_dto.dart';
import '../models/rjsc_registration_process_model.dart';
import '../services/rjsc_service.dart';
import '../services/rjsc_registration_process_service.dart';
import 'rjsc_details_page.dart';

class MyRjscProcessControlScreen extends StatefulWidget {
  const MyRjscProcessControlScreen({super.key});

  @override
  State<MyRjscProcessControlScreen> createState() =>
      _MyRjscProcessControlScreenState();
}

class _MyRjscProcessControlScreenState
    extends State<MyRjscProcessControlScreen> {
  bool _loading = true;
  String? _error;
  String _myUserId = '';
  final List<_Entry> _entries = [];

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
  });

  try {
    _myUserId = await AuthService.getUserId() ?? '';
    debugPrint('🟦 myUserId = $_myUserId');

    if (_myUserId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please log in';
      });
      return;
    }

    // 1. Fetch ALL RJSC entries
    final rjscRes = await RjscService.findAll();
    debugPrint('🟦 raw rjsc response = $rjscRes');

    if (rjscRes['status'] != 'success') {
      setState(() {
        _loading = false;
        _error = rjscRes['message'] ?? 'Failed to load RJSC entries';
      });
      return;
    }

    final allRjsc = RjscService.parseRjscList(rjscRes);
    debugPrint('🟦 parsed rjsc = ${allRjsc.length}');

    // 2. Filter: keep only those whose registrationProcess.userId == myUserId
    for (final rjsc in allRjsc) {
      final process = rjsc.registrationProcess;

      debugPrint('   → rjsc.id=${rjsc.id} '
          'process?.userId=${process?.userId} '
          'process?.status=${process?.status}');

      if (process == null) {
        debugPrint('   ⏭️ Skipping — no registrationProcess');
        continue;
      }

      if (process.userId != _myUserId) {
        debugPrint('   ⏭️ Skipping — userId mismatch '
            '(${process.userId} != $_myUserId)');
        continue;
      }

      _entries.add(_Entry(process: process, rjsc: rjsc));
    }

    debugPrint('🟩 entries = ${_entries.length}');

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

  // Convert the nested model (from process DTO) into a DTO-shaped object
  // so the details page can consume it uniformly.
  RjscResponseDTO _rjscModelToDto(dynamic rjscModel) {
    return RjscResponseDTO(
      id: rjscModel.id,
      userId: rjscModel.userId,
      userName: '',
      compilenceService: rjscModel.compilenceService,
      registrationNo: rjscModel.registrationNo,
      email: rjscModel.email,
      companyName: rjscModel.companyName,
      year: rjscModel.year,
      documents: rjscModel.documents,
    );
  }

  Future<void> _openDetails(_Entry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RjscDetailsPage(rjsc: entry.rjsc),
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
          'My RJSC Processes',
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
                      color: const Color(0xFF0B5D36),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, i) => _entryCard(_entries[i]),
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
                  backgroundColor: const Color(0xFF0B5D36)),
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
            Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No RJSC processes assigned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accept an RJSC filing from its details page to start managing it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryCard(_Entry entry) {
    final r = entry.rjsc;
    final p = entry.process;
    final isApproved = p.status == true;

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
                      color: const Color(0xFF0B5D36).withOpacity(0.1),
                    ),
                    child: const Icon(Icons.verified_user,
                        color: Color(0xFF0B5D36), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.companyName.isEmpty ? 'Untitled' : r.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Reg: ${r.registrationNo} · ${r.compilenceService}',
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
                      p.userName.isEmpty ? 'Unknown' : p.userName,
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
    final color =
        approved ? const Color(0xFF0B5D36) : const Color(0xFFE65100);
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
  final RjscRegistrationProcessResponseDTO process;
  final RjscResponseDTO rjsc;
  _Entry({required this.process, required this.rjsc});
}