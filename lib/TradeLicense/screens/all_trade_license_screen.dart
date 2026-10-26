// lib/TradeLicense/screens/all_trade_license_screen.dart

import 'package:flutter/material.dart';
import '../models/trade_license_response_dto.dart';
import '../services/trade_license_service.dart';
import 'widgets/trade_license_card.dart';
import 'trade_license_details_screen.dart';

class AllTradeLicenseScreen extends StatefulWidget {
  const AllTradeLicenseScreen({super.key});

  @override
  State<AllTradeLicenseScreen> createState() => _AllTradeLicenseScreenState();
}

class _AllTradeLicenseScreenState extends State<AllTradeLicenseScreen>
    with SingleTickerProviderStateMixin {
  // All items from server
  List<TradeLicenseResponseDTO> _allItems = [];

  // Split lists
  List<TradeLicenseResponseDTO> _approvedItems = [];
  List<TradeLicenseResponseDTO> _pendingItems = [];

  // Filtered views (search applied)
  List<TradeLicenseResponseDTO> _approvedFiltered = [];
  List<TradeLicenseResponseDTO> _pendingFiltered = [];

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
        // Recompute filtered views on tab switch so search stays consistent
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

    final result = await TradeLicenseService.findAll();
    if (!mounted) return;

    if (result['status'] == 'success') {
      final list = TradeLicenseService.parseList(result);

      final approved = <TradeLicenseResponseDTO>[];
      final pending = <TradeLicenseResponseDTO>[];

      for (final c in list) {
        final process = c.tradeLicenseRegistrationProcess;
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
  // Search — applied to both tabs simultaneously
  // ============================================================
  void _applySearch() {
    final q = _searchController.text.trim().toLowerCase();

    List<TradeLicenseResponseDTO> filter(List<TradeLicenseResponseDTO> src) {
      if (q.isEmpty) return List<TradeLicenseResponseDTO>.from(src);
      return src.where((c) {
        return c.buisnessName.toLowerCase().contains(q) ||
            c.userName.toLowerCase().contains(q) ||
            c.buisnessType.toLowerCase().contains(q) ||
            c.buisnessCategory.toLowerCase().contains(q);
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
          'Trade Licenses',
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
          labelColor: const Color(0xFF1E7A3A),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF1E7A3A),
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
                hintText: 'Search by name, type, owner...',
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
    required List<TradeLicenseResponseDTO> items,
    required bool isApprovedTab,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApprovedTab
                  ? Icons.storefront_outlined
                  : Icons.hourglass_empty,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No ${isApprovedTab ? 'approved' : 'pending'} trade licenses yet'
                  : 'No results matching your search',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
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
          return TradeLicenseCard(
            license: item,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TradeLicenseDetailsScreen(
                  license: item,
                  isOwner: false,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}