// lib/TradeLicense/screens/my_assigned_trade_license_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trade_license_registration_process_model.dart';
import '../models/trade_license_response_dto.dart';
import '../services/trade_license_registration_process_service.dart';
import '../services/trade_license_service.dart';
import 'trade_license_details_screen.dart';

/// Shows only the Trade License registration processes where the current user
/// is assigned as an advocate (`advocateId` from SharedPreferences).
/// Lists only the Trade License business name, and on tap loads the full
/// [TradeLicenseResponseDTO] and navigates to [TradeLicenseDetailsScreen].
class MyAssignedTradeLicensePage extends StatefulWidget {
  const MyAssignedTradeLicensePage({super.key});

  @override
  State<MyAssignedTradeLicensePage> createState() =>
      _MyAssignedTradeLicensePageState();
}

class _MyAssignedTradeLicensePageState
    extends State<MyAssignedTradeLicensePage> {
  static const Color _primaryGreen = Color(0xFF1E7A3A);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF64748B);

  final TextEditingController _searchController = TextEditingController();

  String _advocateName = '';
  bool _isLoading = true;
  String? _error;

  /// Processes assigned to the current advocate.
  List<TradeLicenseRegistrationProcessResponseDTO> _processes = [];

  /// Cache of `tradeLicenseId` -> `TradeLicenseResponseDTO` when `process.tradeLicense`
  /// is null or missing `buisnessName`.
  Map<String, TradeLicenseResponseDTO> _licenseById = {};

  String _resolveTradeLicenseId(
      TradeLicenseRegistrationProcessResponseDTO process) {
    final directId = process.tradeLicenseId.trim();
    if (directId.isNotEmpty) return directId;

    final nestedId = process.tradeLicense?.id?.trim() ?? '';
    if (nestedId.isNotEmpty) return nestedId;

    // Fallback: match by process id in cached TradeLicenseResponseDTOs
    final procId = process.id?.trim() ?? '';
    if (procId.isNotEmpty) {
      for (final entry in _licenseById.entries) {
        if (entry.value.tradeLicenseRegistrationProcess?.id?.trim() ==
            procId) {
          return entry.key;
        }
      }
    }
    return '';
  }

  String _resolveBusinessName(
      TradeLicenseRegistrationProcessResponseDTO process) {
    final nestedName = process.tradeLicense?.buisnessName.trim() ?? '';
    if (nestedName.isNotEmpty) return nestedName;

    final tlId = _resolveTradeLicenseId(process);
    return _licenseById[tlId]?.buisnessName.trim() ?? '';
  }

  String _resolveDisplayAdvocateName() {
    if (_advocateName.trim().isNotEmpty) return _advocateName.trim();
    for (final p in _processes) {
      if (p.advocateName.trim().isNotEmpty) {
        return p.advocateName.trim();
      }
    }
    return 'Advocate';
  }

  List<TradeLicenseRegistrationProcessResponseDTO> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _processes;
    return _processes.where((p) {
      return _resolveBusinessName(p).toLowerCase().contains(q);
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
  // LOAD ASSIGNED PROCESSES
  // ============================================================
  Future<void> _loadProcesses() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _processes = [];
      _licenseById = {};
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
          _advocateName = '';
          _isLoading = false;
          _error =
              'Advocate account not found. Please log in again as an advocate.';
        });
        return;
      }

      _advocateName = savedAdvocateName;

      final res =
          await TradeLicenseRegistrationProcessService.findByAdvocateId(
              advocateId);

      if (res['status'] != 'success') {
        setState(() {
          _isLoading = false;
          _error = res['message']?.toString() ?? 'Failed to load processes';
        });
        return;
      }

      final allParsed =
          TradeLicenseRegistrationProcessService.parseListDTO(res);

      // Keep strictly processes assigned to this advocateId
      final assignedList = allParsed
          .where((p) => p.advocateId.trim() == advocateId)
          .toList();

      // Capture advocateName from DTO if not stored locally
      if (_advocateName.isEmpty) {
        for (final item in assignedList) {
          if (item.advocateName.trim().isNotEmpty) {
            _advocateName = item.advocateName.trim();
            await prefs.setString('advocateName', _advocateName);
            break;
          }
        }
      }

      final fetchedMap = <String, TradeLicenseResponseDTO>{};
      final missingIds = <String>{};
      bool hasUnlinkedProcess = false;

      for (final item in assignedList) {
        final tlId = item.tradeLicenseId.trim().isNotEmpty
            ? item.tradeLicenseId.trim()
            : (item.tradeLicense?.id?.trim() ?? '');
        final hasEmbeddedName = item.tradeLicense != null &&
            item.tradeLicense!.buisnessName.trim().isNotEmpty;

        if (tlId.isNotEmpty && !hasEmbeddedName) {
          missingIds.add(tlId);
        } else if (tlId.isEmpty) {
          hasUnlinkedProcess = true;
        }
      }

      if (missingIds.isNotEmpty) {
        await Future.wait(missingIds.map((id) async {
          try {
            final tlRes = await TradeLicenseService.findById(id);
            final tlObj = TradeLicenseService.parseSingle(tlRes);
            if (tlObj != null && (tlObj.id?.isNotEmpty ?? false)) {
              fetchedMap[tlObj.id!] = tlObj;
            }
          } catch (_) {}
        }));
      }

      if (hasUnlinkedProcess) {
        try {
          final allRes = await TradeLicenseService.findAll();
          final allLicenses = TradeLicenseService.parseList(allRes);
          for (final tl in allLicenses) {
            if (tl.id != null && tl.id!.isNotEmpty) {
              fetchedMap[tl.id!] = tl;
            }
          }
        } catch (_) {}
      }

      String nameForSort(TradeLicenseRegistrationProcessResponseDTO p) {
        final embedded = p.tradeLicense?.buisnessName.trim() ?? '';
        if (embedded.isNotEmpty) return embedded.toLowerCase();

        final directId = p.tradeLicenseId.trim().isNotEmpty
            ? p.tradeLicenseId.trim()
            : (p.tradeLicense?.id?.trim() ?? '');
        if (directId.isNotEmpty && fetchedMap.containsKey(directId)) {
          return fetchedMap[directId]!.buisnessName.trim().toLowerCase();
        }

        final procId = p.id?.trim() ?? '';
        if (procId.isNotEmpty) {
          for (final tl in fetchedMap.values) {
            if (tl.tradeLicenseRegistrationProcess?.id?.trim() == procId) {
              return tl.buisnessName.trim().toLowerCase();
            }
          }
        }
        return '';
      }

      assignedList.sort((a, b) => nameForSort(a).compareTo(nameForSort(b)));

      if (!mounted) return;
      setState(() {
        _licenseById = fetchedMap;
        _processes = assignedList;
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
  // TAP → load full TradeLicenseResponseDTO → navigate to details
  // ============================================================
  Future<void> _openTradeLicense(
      TradeLicenseRegistrationProcessResponseDTO process) async {
    final tlId = _resolveTradeLicenseId(process);
    if (tlId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This process has no Trade License attached'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _primaryGreen),
      ),
    );

    TradeLicenseResponseDTO? fresh;
    String? error;
    try {
      final res = await TradeLicenseService.findById(tlId);
      fresh = TradeLicenseService.parseSingle(res);
      if (fresh == null) {
        error = res['message']?.toString() ?? 'Trade license not found';
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
          content: Text('Failed to load Trade License: ${error ?? "unknown"}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TradeLicenseDetailsScreen(
          license: fresh!,
          isOwner: false,
        ),
      ),
    );

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
          'My Assigned Trade Licenses',
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
          hintText: 'Search by business name…',
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
          const Icon(Icons.store_outlined, size: 16, color: _textGrey),
          const SizedBox(width: 6),
          Text(
            shown == total
                ? '$total ${total == 1 ? "Trade License" : "Trade Licenses"}'
                : '$shown of $total Trade Licenses',
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
          'No trade licenses match your search',
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
          final businessName = _resolveBusinessName(process);
          return _TradeLicenseProcessTile(
            process: process,
            businessName: businessName,
            onTap: () => _openTradeLicense(process),
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
                Icons.storefront_outlined,
                size: 48,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Trade Licenses assigned yet',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Trade License filings assigned to you as an advocate will appear here.',
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
// Minimal tile — Trade License business name + status chip
// ============================================================
class _TradeLicenseProcessTile extends StatelessWidget {
  final TradeLicenseRegistrationProcessResponseDTO process;
  final String businessName;
  final VoidCallback onTap;

  const _TradeLicenseProcessTile({
    required this.process,
    required this.businessName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = businessName.trim().isEmpty
        ? 'Untitled Business'
        : businessName.trim();
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
                child: const Icon(Icons.store,
                    color: Color(0xFF1E7A3A), size: 22),
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
        completed ? const Color(0xFF1E7A3A) : const Color(0xFFB45309);
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