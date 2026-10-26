// lib/Copyright/screens/copyright_process_control_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../models/copyright_registration_process_model.dart';
import '../services/copyright_registration_process_service.dart';
import '../services/copyright_service.dart';
import '../models/copyright_response_dto.dart';
import 'copyright_details_screen.dart';

/// Lists all copyrights whose registration process is controlled by the
/// currently-logged-in center admin.
class CopyrightProcessControlScreen extends StatefulWidget {
  const CopyrightProcessControlScreen({super.key});

  @override
  State<CopyrightProcessControlScreen> createState() =>
      _CopyrightProcessControlScreenState();
}

class _CopyrightProcessControlScreenState
    extends State<CopyrightProcessControlScreen> {
  bool _loading = true;
  String? _error;
  String _myUserId = '';

  /// Each entry = { process, copyright }
  final List<_ProcessEntry> _entries = [];

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
      if (_myUserId.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Please log in';
        });
        return;
      }

      // 1) All processes I own
      final procRes =
          await CopyrightRegistrationProcessService.findByUserId(_myUserId);

      if (procRes['status'] != 'success') {
        setState(() {
          _loading = false;
          _error = procRes['message'] ?? 'Failed to load processes';
        });
        return;
      }

      final procs = CopyrightRegistrationProcessService.parseList(procRes);

      // 2) For each process, fetch the copyright details
      for (final p in procs) {
        if (p.copyrightId.isEmpty) continue;

        final cRes = await CopyrightService.findById(p.copyrightId);
        final dto = CopyrightService.parseSingle(cRes);
        if (dto != null) {
          _entries.add(_ProcessEntry(process: p, copyright: dto));
        }
      }

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

  Future<void> _openDetails(_ProcessEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CopyrightDetailsScreen(
          copyright: entry.copyright,
          isOwner: entry.copyright.userId == _myUserId,
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
        title: const Text(
          'My Copyright Processes',
          style: TextStyle(color: Colors.black87, fontSize: 18),
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
                      color: const Color(0xFF1A3FBF),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, i) =>
                            _entryCard(_entries[i]),
                      ),
                    ),
    );
  }

  // =========================================================================
  // VIEWS
  // =========================================================================

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
                  backgroundColor: const Color(0xFF1A3FBF)),
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
              'No copyright processes assigned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accept a copyright from its details page to start managing it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryCard(_ProcessEntry entry) {
    final c = entry.copyright;
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
                      color: const Color(0xFF1A3FBF).withOpacity(0.1),
                    ),
                    child: const Icon(Icons.copyright,
                        color: Color(0xFF1A3FBF), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.titleOfWork.isEmpty
                              ? 'Untitled'
                              : c.titleOfWork,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${c.typeOfWork} · ${c.yearOfCreation.year}',
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
                      c.userName.isEmpty ? 'Unknown' : c.userName,
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
                    '${p.stpes.length} steps',
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
        approved ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
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

class _ProcessEntry {
  final CopyrightRegistrationProcessResponseDTO process;
  final CopyrightResponseDTO copyright;

  _ProcessEntry({required this.process, required this.copyright});
}