// lib/CompanyPages/advocate_companies_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../CompanyPages/company_service.dart';
import '../CompanyPages/company_response.dart';
import '../CompanyPages/company_details_page.dart';
import '../CompanyPages/registration_process_service.dart';
import '../CompanyPages/registration_process_response.dart';

/// Shows only the companies where the **current user (advocate)**
/// is assigned in the registration process.
///
/// Data flow:
///   1. advocateId  ← SharedPreferences('advocateId')
///   2. processes   ← RegistrationProcessService.getProcessesByAdvocateId(advocateId)
///   3. companies   ← CompanyService.getCompanyById(process.companyId) for each
///   4. tap         → CompanyDetailsPage(companyId: ...)
class AdvocateCompaniesPage extends StatefulWidget {
  const AdvocateCompaniesPage({Key? key}) : super(key: key);

  @override
  State<AdvocateCompaniesPage> createState() => _AdvocateCompaniesPageState();
}

class _AdvocateCompaniesPageState extends State<AdvocateCompaniesPage> {
  final CompanyService _companyService = CompanyService();
  final RegistrationProcessService _processService =
      RegistrationProcessService();

  final TextEditingController _searchController = TextEditingController();

  String? _advocateId;
  bool _isLoading = true;
  String? _error;

  /// Combined view: each process paired with its resolved company.
  List<_AdvocateCompanyEntry> _entries = [];

  /// Filtered view based on the search box.
  List<_AdvocateCompanyEntry> get _filteredEntries {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _entries;
    return _entries
        .where((e) =>
            e.company.companyName.toLowerCase().contains(q) ||
            (e.process.advocateName).toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadAdvocateCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================
  Future<void> _loadAdvocateCompanies() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _entries = [];
    });

    try {
      // 1. Read advocateId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final advocateId = prefs.getString('advocateId');

      if (advocateId == null || advocateId.isEmpty) {
        setState(() {
          _advocateId = null;
          _isLoading = false;
          _error =
              'Advocate ID not found. Please log in again as an advocate.';
        });
        return;
      }

      _advocateId = advocateId;

      // 2. Fetch all registration processes assigned to this advocate
      final processes =
          await _processService.getProcessesByAdvocateId(advocateId);

      if (processes.isEmpty) {
        setState(() {
          _isLoading = false;
          _entries = [];
        });
        return;
      }

      // 3. For each process, load its company (parallel)
      final results = await Future.wait(
        processes.map((p) async {
          try {
            final company = await _companyService.getCompanyById(p.companyId);
            return _AdvocateCompanyEntry(process: p, company: company);
          } catch (e) {
            // If a single company fails, skip it rather than failing everything
            print('⚠️ Failed to load company ${p.companyId}: $e');
            return null;
          }
        }),
      );

      final entries = results
          .whereType<_AdvocateCompanyEntry>()
          .where((e) => e.company.id != null && e.company.id!.isNotEmpty)
          .toList();

      // Sort by company name for a stable UI
      entries.sort((a, b) => a.company.companyName
          .toLowerCase()
          .compareTo(b.company.companyName.toLowerCase()));

      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================
  Future<void> _openCompany(_AdvocateCompanyEntry entry) async {
    final companyId = entry.company.id!;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(companyId: companyId),
      ),
    );
    // Refresh on return so updated process/status is reflected
    if (mounted) await _loadAdvocateCompanies();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Assigned Companies',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadAdvocateCompanies,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    if (_entries.isEmpty) {
      return _buildEmpty();
    }
    return Column(
      children: [
        _buildSearchBar(),
        _buildSummaryBar(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by company name…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final shown = _filteredEntries.length;
    final total = _entries.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.business, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            shown == total
                ? '$total ${total == 1 ? "company" : "companies"}'
                : '$shown of $total companies',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_advocateId != null)
            Flexible(
              child: Text(
                'Advocate ID: ${_shortId(_advocateId!)}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final list = _filteredEntries;
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No companies match your search',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final entry = list[i];
        return _CompanyCard(
          entry: entry,
          onTap: () => _openCompany(entry),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center_outlined,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No companies assigned yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Companies that you accept as a center admin will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadAdvocateCompanies,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAdvocateCompanies,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}…${id.substring(id.length - 4)}';
  }
}

// ============================================================
// INTERNAL: Pair of process + resolved company
// ============================================================
class _AdvocateCompanyEntry {
  final RegistrationProcessResponse process;
  final CompanyResponse company;

  _AdvocateCompanyEntry({
    required this.process,
    required this.company,
  });
}

// ============================================================
// Company card widget
// ============================================================
class _CompanyCard extends StatelessWidget {
  final _AdvocateCompanyEntry entry;
  final VoidCallback onTap;

  const _CompanyCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final company = entry.company;
    final process = entry.process;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.business,
                        color: Colors.blue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.companyName.isEmpty
                              ? 'Unnamed Company'
                              : company.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${company.type} • ${company.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Status + share value + steps
              Row(
                children: [
                  _statusChip(process.status),
                  const SizedBox(width: 8),
                  _infoChip(
                    icon: Icons.attach_money,
                    text:
                        '৳${process.shareValuePerShare.toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  if (process.steps.isNotEmpty)
                    _infoChip(
                      icon: Icons.checklist,
                      text: '${process.steps.length} steps',
                      color: Colors.orange,
                    ),
                ],
              ),

              if (process.advocateName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.gavel,
                        size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Advocate: ${process.advocateName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(bool completed) {
    final color = completed ? Colors.green : Colors.orange;
    final label = completed ? 'Completed' : 'In Progress';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.timelapse,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}