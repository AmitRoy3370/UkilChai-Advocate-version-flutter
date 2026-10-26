// lib/Copyright/screens/all_copyright_screen.dart

import 'package:flutter/material.dart';
import '../models/copyright_response_dto.dart';
import '../services/copyright_service.dart';
import '../screens/widgets/copyright_card.dart';
import 'copyright_details_screen.dart';

class AllCopyrightScreen extends StatefulWidget {
  const AllCopyrightScreen({super.key});

  @override
  State<AllCopyrightScreen> createState() => _AllCopyrightScreenState();
}

class _AllCopyrightScreenState extends State<AllCopyrightScreen>
    with SingleTickerProviderStateMixin {
  // All items from server
  List<CopyrightResponseDTO> _allItems = [];

  // Split lists
  List<CopyrightResponseDTO> _approvedItems = [];
  List<CopyrightResponseDTO> _pendingItems = [];

  // Filtered views (search applied per tab)
  List<CopyrightResponseDTO> _approvedFiltered = [];
  List<CopyrightResponseDTO> _pendingFiltered = [];

  bool _isLoading = true;
  String? _error;

  final _searchController = TextEditingController();

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _applySearch();
        setState(() {});
      }
    });
    _loadData();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // Load
  // ============================================================
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await CopyrightService.findAll();

    if (!mounted) return;

    if (result['status'] == 'success') {
      final list = CopyrightService.parseList(result);

      final approved = <CopyrightResponseDTO>[];
      final pending = <CopyrightResponseDTO>[];

      for (final c in list) {
        final process = c.registrationProcess;
        final isApproved = process != null && process.status == true;
        if (isApproved) {
          approved.add(c);
        } else {
          pending.add(c);
        }
      }

      setState(() {
        _allItems = list;
        _approvedItems = approved;
        _pendingItems = pending;
        _isLoading = false;
      });

      _applySearch();
    } else {
      setState(() {
        _isLoading = false;
        _error = result['message'] ?? 'Failed to load';
      });
    }
  }

  // ============================================================
  // Search — applied to both tabs
  // ============================================================
  void _applySearch() {
    final q = _searchController.text.trim().toLowerCase();

    List<CopyrightResponseDTO> filter(List<CopyrightResponseDTO> src) {
      if (q.isEmpty) return List<CopyrightResponseDTO>.from(src);
      return src.where((c) {
        return c.titleOfWork.toLowerCase().contains(q) ||
            c.author.toLowerCase().contains(q) ||
            c.userName.toLowerCase().contains(q) ||
            c.typeOfWork.toLowerCase().contains(q);
      }).toList();
    }

    setState(() {
      _approvedFiltered = filter(_approvedItems);
      _pendingFiltered = filter(_pendingItems);
    });
  }

  // ============================================================
  // Build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Copyrights',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A3FBF),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF1A3FBF),
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 16),
                  const SizedBox(width: 6),
                  Text('Approved (${_approvedFiltered.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top, size: 16),
                  const SizedBox(width: 6),
                  Text('Pending (${_pendingFiltered.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, author, type...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Body: tabs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(
                            items: _approvedFiltered,
                            isApprovedTab: true,
                          ),
                          _buildList(
                            items: _pendingFiltered,
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
              size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildList({
    required List<CopyrightResponseDTO> items,
    required bool isApprovedTab,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isApprovedTab
                    ? Icons.verified_outlined
                    : Icons.hourglass_empty,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'No ${isApprovedTab ? 'approved' : 'pending'} copyrights yet'
                    : 'No results matching your search',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return CopyrightCard(
            copyright: item,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CopyrightDetailsScreen(
                  copyright: item,
                  isOwner: false, // All copyright - not owner
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}