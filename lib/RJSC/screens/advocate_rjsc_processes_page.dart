import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rjsc_registration_process_model.dart';
import '../models/rjsc_response_dto.dart';
import '../services/rjsc_registration_process_service.dart';
import '../services/rjsc_service.dart';
import 'rjsc_details_page.dart';

/// Shows every RJSC registration process assigned to the **current advocate**
/// (advocateId from SharedPreferences), displays the advocate's name (never ID),
/// resolves RJSC company names reliably, and navigates to [RjscDetailsPage] on tap.
class AdvocateRjscProcessesPage extends StatefulWidget {
  const AdvocateRjscProcessesPage({super.key});

  @override
  State<AdvocateRjscProcessesPage> createState() =>
      _AdvocateRjscProcessesPageState();
}

class _AdvocateRjscProcessesPageState
    extends State<AdvocateRjscProcessesPage> {
  static const Color _primaryGreen = Color(0xFF0B5D36);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF64748B);

  final TextEditingController _searchController = TextEditingController();

  String? _advocateId;
  String _advocateName = '';
  bool _isLoading = true;
  String? _error;

  /// Raw processes returned by the backend.
  List<RjscRegistrationProcessResponseDTO> _processes = [];

  /// Fallback map from `rjscId` -> `RjscResponseDTO` when `process.rjsc` is null
  /// or missing `companyName`.
  Map<String, RjscResponseDTO> _rjscById = {};

  String _resolveRjscId(RjscRegistrationProcessResponseDTO process) {
    final nestedId = process.rjsc?.id?.trim() ?? '';
    if (nestedId.isNotEmpty) return nestedId;

    if (process.rjscId.trim().isNotEmpty) {
      return process.rjscId.trim();
    }

    // Fallback: match by process id in _rjscById values
    final procId = process.id?.trim() ?? '';
    if (procId.isNotEmpty) {
      for (final entry in _rjscById.entries) {
        if (entry.value.registrationProcess?.id?.trim() == procId) {
          return entry.key;
        }
      }
    }
    return '';
  }

  String _resolveCompanyName(RjscRegistrationProcessResponseDTO process) {
    final nestedName = process.rjsc?.companyName.trim() ?? '';
    if (nestedName.isNotEmpty) return nestedName;

    final rjscId = _resolveRjscId(process);
    return _rjscById[rjscId]?.companyName.trim() ?? '';
  }

  String _resolveDisplayAdvocateName() {
    if (_advocateName.trim().isNotEmpty) {
      return _advocateName.trim();
    }
    for (final p in _processes) {
      if (p.advocateName.trim().isNotEmpty) {
        return p.advocateName.trim();
      }
    }
    return 'Advocate';
  }

  /// Filtered by the search box (company name only).
  List<RjscRegistrationProcessResponseDTO> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _processes;
    return _processes.where((p) {
      final name = _resolveCompanyName(p).toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadProcesses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================
  Future<void> _loadProcesses() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _processes = [];
      _rjscById = {};
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final advocateId = prefs.getString('advocateId')?.trim() ?? '';
      final savedAdvocateName = (prefs.getString('advocateName') ??
              prefs.getString('userName') ??
              prefs.getString('name') ??
              '')
          .trim();

      if (advocateId.isEmpty) {
        setState(() {
          _advocateId = null;
          _advocateName = '';
          _isLoading = false;
          _error =
              'Advocate account not found. Please log in again as an advocate.';
        });
        return;
      }

      _advocateId = advocateId;
      _advocateName = savedAdvocateName;

      final res =
          await RjscRegistrationProcessService.findByAdvocateId(advocateId);

      if (res['status'] != 'success') {
        setState(() {
          _isLoading = false;
          _error = res['message']?.toString() ?? 'Failed to load processes';
        });
        return;
      }

      final list = RjscRegistrationProcessService.parseList(res);

      // Extract advocate name from response DTO if not already saved locally.
      if (_advocateName.isEmpty) {
        for (final item in list) {
          if (item.advocateName.trim().isNotEmpty) {
            _advocateName = item.advocateName.trim();
            await prefs.setString('advocateName', _advocateName);
            break;
          }
        }
      }

      final fetchedMap = <String, RjscResponseDTO>{};

      // 1) Collect RJSC IDs that are missing embedded companyName/rjsc object.
      final missingIds = <String>{};
      bool hasUnlinkedProcess = false;

      for (final item in list) {
        final rjscId = (item.rjsc?.id?.trim().isNotEmpty == true)
            ? item.rjsc!.id!.trim()
            : item.rjscId.trim();
        final hasEmbeddedName =
            item.rjsc != null && item.rjsc!.companyName.trim().isNotEmpty;

        if (rjscId.isNotEmpty && !hasEmbeddedName) {
          missingIds.add(rjscId);
        } else if (rjscId.isEmpty) {
          hasUnlinkedProcess = true;
        }
      }

      if (missingIds.isNotEmpty) {
        await Future.wait(missingIds.map((id) async {
          try {
            final rjscRes = await RjscService.findById(id);
            final rjscObj = RjscService.parseSingle(rjscRes);
            if (rjscObj != null && (rjscObj.id?.isNotEmpty ?? false)) {
              fetchedMap[rjscObj.id!] = rjscObj;
            }
          } catch (_) {}
        }));
      }

      // 2) Fallback if backend DTO returned neither `rjsc` nor `rjscId`.
      if (hasUnlinkedProcess) {
        try {
          final allRes = await RjscService.findAll();
          final allRjsc = RjscService.parseRjscList(allRes);
          for (final r in allRjsc) {
            if (r.id != null && r.id!.isNotEmpty) {
              fetchedMap[r.id!] = r;
            }
          }
        } catch (_) {}
      }

      // Sort by resolved RJSC company name (case-insensitive).
      String nameForSort(RjscRegistrationProcessResponseDTO p) {
        final embedded = p.rjsc?.companyName.trim() ?? '';
        if (embedded.isNotEmpty) return embedded.toLowerCase();

        final directId = (p.rjsc?.id?.trim().isNotEmpty == true)
            ? p.rjsc!.id!.trim()
            : p.rjscId.trim();
        if (directId.isNotEmpty && fetchedMap.containsKey(directId)) {
          return fetchedMap[directId]!.companyName.trim().toLowerCase();
        }

        final procId = p.id?.trim() ?? '';
        if (procId.isNotEmpty) {
          for (final r in fetchedMap.values) {
            if (r.registrationProcess?.id?.trim() == procId) {
              return r.companyName.trim().toLowerCase();
            }
          }
        }
        return '';
      }

      list.sort((a, b) => nameForSort(a).compareTo(nameForSort(b)));

      if (!mounted) return;
      setState(() {
        _rjscById = fetchedMap;
        _processes = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // TAP → fetch fresh RJSC by id → open details
  // ============================================================
  Future<void> _openRjsc(RjscRegistrationProcessResponseDTO process) async {
    final rjscId = _resolveRjscId(process);
    if (rjscId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This process has no RJSC attached'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Blocking progress while we fetch fresh RJSC.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _primaryGreen),
      ),
    );

    RjscResponseDTO? fresh;
    String? error;
    try {
      final res = await RjscService.findById(rjscId);
      fresh = RjscService.parseSingle(res);
      if (fresh == null) {
        error = res['message']?.toString() ?? 'RJSC not found';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;

    if (fresh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load RJSC: ${error ?? "unknown"}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RjscDetailsPage(rjsc: fresh!),
      ),
    );

    // Refresh on return (status / steps may have changed).
    if (mounted) await _loadProcesses();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'My RJSC Clients',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _primaryGreen),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadProcesses,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryGreen),
      );
    }
    if (_error != null) return _buildError();
    if (_processes.isEmpty) return _buildEmpty();

    return Column(
      children: [
        _buildSearchBar(),
        _buildSummaryBar(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by company name…',
          hintStyle: GoogleFonts.inter(color: _textGrey, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: _textGrey),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _searchController.clear(),
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final shown = _filtered.length;
    final total = _processes.length;
    final displayAdvocateName = _resolveDisplayAdvocateName();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.business, size: 16, color: _textGrey),
          const SizedBox(width: 6),
          Text(
            shown == total
                ? '$total ${total == 1 ? "RJSC filing" : "RJSC filings"}'
                : '$shown of $total filings',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gavel, size: 13, color: _primaryGreen),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    displayAdvocateName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: _textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No filings match your search',
          style: GoogleFonts.inter(fontSize: 13, color: _textGrey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProcesses,
      color: _primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final process = list[i];
          final companyName = _resolveCompanyName(process);
          return _RjscProcessTile(
            process: process,
            companyName: companyName,
            onTap: () => _openRjsc(process),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_center_outlined,
                size: 48,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No RJSC filings assigned yet',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'RJSC filings assigned to you as an advocate will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: _textGrey),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadProcesses,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _primaryGreen),
                foregroundColor: _primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
            const Icon(Icons.error_outline,
                size: 60, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: _textGrey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProcesses,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Minimal tile — RJSC company name + status chip
// ============================================================
class _RjscProcessTile extends StatelessWidget {
  final RjscRegistrationProcessResponseDTO process;
  final String companyName;
  final VoidCallback onTap;

  const _RjscProcessTile({
    required this.process,
    required this.companyName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        companyName.trim().isEmpty ? 'Untitled RJSC' : companyName.trim();
    final isCompleted = process.status;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apartment,
                    color: Color(0xFF0B5D36), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(completed: isCompleted),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool completed;
  const _StatusChip({required this.completed});

  @override
  Widget build(BuildContext context) {
    final color =
        completed ? const Color(0xFF0B5D36) : const Color(0xFFB45309);
    final bg =
        completed ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.timelapse,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            completed ? 'Done' : 'Active',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}