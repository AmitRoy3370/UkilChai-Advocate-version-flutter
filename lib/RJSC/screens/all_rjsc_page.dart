// lib/RJSC/screens/all_rjsc_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/rjsc_response_dto.dart';
import '../services/rjsc_service.dart';
import 'rjsc_details_page.dart';

class AllRjscPage extends StatefulWidget {
  const AllRjscPage({super.key});

  @override
  State<AllRjscPage> createState() => _AllRjscPageState();
}

class _AllRjscPageState extends State<AllRjscPage>
    with SingleTickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF0B5D36);
  static const Color _primaryOrange = Color(0xFFE65100);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF64748B);

  bool _isLoading = true;
  String? _error;

  // All items from server
  List<RjscResponseDTO> _allList = [];

  // Split lists
  List<RjscResponseDTO> _approvedList = [];
  List<RjscResponseDTO> _pendingList = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ============ Load Data ============
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await RjscService.findAll();

      if (result['status'] == 'success') {
        final allList = RjscService.parseRjscList(result);

        final approved = <RjscResponseDTO>[];
        final pending = <RjscResponseDTO>[];

        for (final rjsc in allList) {
          final process = rjsc.registrationProcess;
          final isApproved = process != null && process.status == true;
          if (isApproved) {
            approved.add(rjsc);
          } else {
            pending.add(rjsc);
          }
        }

        setState(() {
          _allList = allList;
          _approvedList = approved;
          _pendingList = pending;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = result['message']?.toString() ?? 'Failed to load';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  // ============ Search Filter ============
  List<RjscResponseDTO> _filter(List<RjscResponseDTO> src) {
    if (_searchQuery.isEmpty) return List<RjscResponseDTO>.from(src);
    final q = _searchQuery.toLowerCase();
    return src.where((r) {
      return r.companyName.toLowerCase().contains(q) ||
          r.registrationNo.toLowerCase().contains(q) ||
          r.compilenceService.toLowerCase().contains(q) ||
          r.userName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'RJSC',
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
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: _primaryGreen),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryGreen,
          unselectedLabelColor: _textGrey,
          indicatorColor: _primaryGreen,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 16),
                  const SizedBox(width: 6),
                  Text('Approved (${_filter(_approvedList).length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top, size: 16),
                  const SizedBox(width: 6),
                  Text('Pending (${_filter(_pendingList).length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by company, reg no, service...',
                hintStyle:
                    GoogleFonts.inter(color: _textGrey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: _textGrey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
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
                  borderSide:
                      const BorderSide(color: _primaryGreen, width: 1.5),
                ),
              ),
            ),
          ),

          // Body: tabs
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryGreen),
                  )
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(
                            items: _filter(_approvedList),
                            isApprovedTab: true,
                          ),
                          _buildList(
                            items: _filter(_pendingList),
                            isApprovedTab: false,
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 60, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: _textGrey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required List<RjscResponseDTO> items,
    required bool isApprovedTab,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isApprovedTab
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApprovedTab
                      ? Icons.verified_outlined
                      : Icons.hourglass_empty,
                  size: 48,
                  color: isApprovedTab ? _primaryGreen : _primaryOrange,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'No ${isApprovedTab ? 'completed' : 'pending'} RJSC found'
                    : 'No match for "$_searchQuery"',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              if (_searchQuery.isEmpty)
                Text(
                  isApprovedTab
                      ? 'Only completed RJSC filings are shown here.'
                      : 'RJSC filings awaiting completion are shown here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _textGrey),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildRjscCard(items[index], isApproved: isApprovedTab);
        },
      ),
    );
  }

  // ============ RJSC Card ============
  Widget _buildRjscCard(RjscResponseDTO rjsc, {required bool isApproved}) {
    final accent = isApproved ? _primaryGreen : _primaryOrange;
    final badgeBg =
        isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RjscDetailsPage(rjsc: rjsc),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              children: [
                // Icon
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment,
                      color: Color(0xFF1565C0), size: 24),
                ),
                const SizedBox(width: 12),
                // Company + user
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rjsc.companyName.isEmpty
                            ? 'Untitled'
                            : rjsc.companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 12, color: _textGrey),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              rjsc.userName.isEmpty
                                  ? 'Unknown User'
                                  : rjsc.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: _textGrey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApproved
                            ? Icons.check_circle
                            : Icons.hourglass_top,
                        size: 11,
                        color: accent,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isApproved ? 'Completed' : 'Pending',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _borderColor),
            const SizedBox(height: 10),

            // Bottom Row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 14, color: _textGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rjsc.compilenceService,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: _textGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Reg: ${rjsc.registrationNo}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _textGrey),
                ),
              ],
            ),

            // Advocate name (only approved will have a process)
            if (isApproved &&
                (rjsc.registrationProcess?.advocateName.isNotEmpty ??
                    false)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.gavel, size: 12, color: _textGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Advocate: ${rjsc.registrationProcess!.advocateName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _textGrey),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}