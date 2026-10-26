// lib/CompanyPages/company_process_control_screen.dart

import 'package:flutter/material.dart';
import '../Auth/AuthService.dart';
import 'company_details_page.dart';
import 'company_service.dart';
import 'company_response.dart';
import 'registration_process_service.dart';
import 'registration_process_response.dart';

class CompanyProcessControlScreen extends StatefulWidget {
  const CompanyProcessControlScreen({super.key});

  @override
  State<CompanyProcessControlScreen> createState() =>
      _CompanyProcessControlScreenState();
}

class _CompanyProcessControlScreenState
    extends State<CompanyProcessControlScreen> {
  final CompanyService _companyService = CompanyService();
  final RegistrationProcessService _processService =
      RegistrationProcessService();

  bool _loading = true;
  String? _error;
  String _myUserId = '';
  final List<_CompanyProcessEntry> _entries = [];

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

      // Get all processes owned by me
      final procs = await _processService.getProcessesByUserId(_myUserId);

      // For each process, load its company details
      for (final p in procs) {
        if (p.companyId.isEmpty) continue;
        try {
          final company = await _companyService.getCompanyById(p.companyId);
          _entries.add(_CompanyProcessEntry(process: p, company: company));
        } catch (_) {
          // Skip companies we can't load
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

  Future<void> _openDetails(_CompanyProcessEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(companyId: entry.company.id ?? ''),
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
          'My Company Processes',
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
                      color: Colors.blue,
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
              'No company processes assigned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Accept a company from its details page to start managing it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryCard(_CompanyProcessEntry entry) {
    final c = entry.company;
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
                      color: Colors.blue.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.business,
                        color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.companyName.isEmpty ? 'Untitled' : c.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${c.type ?? '-'} · ${c.category ?? '-'}',
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
                      c.creatorName ?? 'Unknown',
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
    final color = approved ? Colors.green.shade700 : Colors.orange.shade700;
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

class _CompanyProcessEntry {
  final RegistrationProcessResponse process;
  final CompanyResponse company;
  _CompanyProcessEntry({required this.process, required this.company});
}