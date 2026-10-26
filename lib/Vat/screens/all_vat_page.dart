// lib/vat/screens/all_vat_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/vat_response_model.dart';
import '../service/vat_service.dart';
import 'my_vat_page.dart' show VatCard; // reuse VatCard from my_vat_page

class AllVatPage extends StatefulWidget {
  const AllVatPage({super.key});

  @override
  State<AllVatPage> createState() => _AllVatPageState();
}

class _AllVatPageState extends State<AllVatPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;

  // Full list from server
  List<VatResponseModel> _allVats = [];

  // Split lists
  List<VatResponseModel> _approvedVats = [];
  List<VatResponseModel> _pendingVats = [];

  String? _userId;

  // Search
  final _searchCtrl = TextEditingController();
  String _query = '';

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Rebuild on tab change so search + counts reflect the active tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // Load
  // ============================================================
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id') ??
          prefs.getString('userId') ??
          prefs.getString('_id');

      // Fetch all VATs
      final list = await VatService.findAll();

      // Split into approved / pending
      final approved = <VatResponseModel>[];
      final pending = <VatResponseModel>[];

      for (final v in list) {
        final process = v.vatRegistrationProcessResponseDTO;
        final isApproved = process != null && process.status == true;
        if (isApproved) {
          approved.add(v);
        } else {
          pending.add(v);
        }
      }

      if (!mounted) return;
      setState(() {
        _allVats = list;
        _approvedVats = approved;
        _pendingVats = pending;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('No such vat') ||
          msg.contains('NoSuchElementException')) {
        setState(() {
          _allVats = [];
          _approvedVats = [];
          _pendingVats = [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = msg.replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // Helpers
  // ============================================================
  bool get _isApprovedTab => _tabController.index == 0;

  List<VatResponseModel> _baseListForTab(int index) =>
      index == 0 ? _approvedVats : _pendingVats;

  List<VatResponseModel> _visibleVatsForTab(int index) {
    final base = _baseListForTab(index);
    if (_query.trim().isEmpty) return base;
    final q = _query.trim().toLowerCase();
    return base.where((v) {
      return v.buisnessName.toLowerCase().contains(q) ||
          v.tinNo.toLowerCase().contains(q) ||
          v.tradeLicenseNo.toLowerCase().contains(q) ||
          v.userName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'VAT',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF1565C0),
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 16),
                  const SizedBox(width: 6),
                  Text('Approved (${_approvedVats.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top, size: 16),
                  const SizedBox(width: 6),
                  Text('Pending (${_pendingVats.length})'),
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
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                icon: Icon(Icons.search,
                    color: Colors.grey.shade500, size: 20),
                hintText: 'Search by name, TIN, or license no.',
                hintStyle:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400),
                border: InputBorder.none,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Body: tabs
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1565C0),
                    ),
                  )
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildListForTab(0),
                          _buildListForTab(1),
                        ],
                      ),
          ),
        ],
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
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListForTab(int index) {
    final list = _visibleVatsForTab(index);
    final isApprovedTab = index == 0;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApprovedTab ? Icons.inbox_outlined : Icons.hourglass_empty,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              _query.isNotEmpty
                  ? 'No matching ${isApprovedTab ? 'approved' : 'pending'} VAT found'
                  : 'No ${isApprovedTab ? 'approved' : 'pending'} VAT available',
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1565C0),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => VatCard(
          vat: list[i],
          currentUserId: _userId,
          onChanged: _load,
        ),
      ),
    );
  }
}