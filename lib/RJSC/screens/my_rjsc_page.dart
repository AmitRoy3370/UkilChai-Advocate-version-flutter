// lib/RJSC/screens/my_rjsc_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rjsc_response_dto.dart';
import '../services/rjsc_service.dart';
import 'rjsc_details_page.dart';

class MyRjscPage extends StatefulWidget {
  const MyRjscPage({super.key});

  @override
  State<MyRjscPage> createState() => _MyRjscPageState();
}

class _MyRjscPageState extends State<MyRjscPage>
    with SingleTickerProviderStateMixin {
  // ============ Theme Colors ============
  static const Color _primaryGreen = Color(0xFF0B5D36);
  static const Color _pendingAmber = Color(0xFFB45309);
  static const Color _pendingBg = Color(0xFFFFFBEB);
  static const Color _lightGreenBg = Color(0xFFECFDF5);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF64748B);

  // ============ Controllers ============
  late TabController _tabController;

  // ============ State ============
  bool _isLoading = true;
  String? _error;
  List<RjscResponseDTO> _approvedList = [];
  List<RjscResponseDTO> _pendingList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============ Load Data ============
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      if (userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
        return;
      }

      final result = await RjscService.findByUserId(userId);

      if (result['status'] == 'success') {
        final all = RjscService.parseRjscList(result);

        // APPROVED: process != null && status == true
        final approved = all.where((r) {
          final p = r.registrationProcess;
          return p != null && p.status == true;
        }).toList();

        // PENDING: process == null OR status != true
        final pending = all.where((r) {
          final p = r.registrationProcess;
          return p == null || p.status != true;
        }).toList();

        setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'My RJSC',
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
            tooltip: 'Refresh',
          ),
        ],
        // ============ TabBar (Only when loaded successfully) ============
        bottom: _isLoading || _error != null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: _primaryGreen,
                    unselectedLabelColor: _textGrey,
                    indicatorColor: _primaryGreen,
                    indicatorWeight: 2.5,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      // ===== Approved Tab =====
                      Tab(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified, size: 16),
                            const SizedBox(width: 6),
                            Text('Approved'),
                            const SizedBox(width: 6),
                            _countBadge(
                              _approvedList.length,
                              _primaryGreen,
                              _lightGreenBg,
                            ),
                          ],
                        ),
                      ),
                      // ===== Pending Tab =====
                      Tab(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.hourglass_top, size: 16),
                            const SizedBox(width: 6),
                            Text('Pending'),
                            const SizedBox(width: 6),
                            _countBadge(
                              _pendingList.length,
                              _pendingAmber,
                              _pendingBg,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      body: _buildBody(),
    );
  }

  // ============ Body Dispatcher ============
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryGreen),
      );
    }

    if (_error != null) {
      return _errorView(_error!);
    }

    if (_approvedList.isEmpty && _pendingList.isEmpty) {
      return _emptyOverallView();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // ===== Approved Tab =====
        _tabContent(
          list: _approvedList,
          isApproved: true,
          emptyMessage: 'No approved RJSC yet',
          emptyIcon: Icons.verified_outlined,
          emptyColor: _primaryGreen,
        ),
        // ===== Pending Tab =====
        _tabContent(
          list: _pendingList,
          isApproved: false,
          emptyMessage: 'No pending RJSC',
          emptyIcon: Icons.hourglass_empty,
          emptyColor: _pendingAmber,
        ),
      ],
    );
  }

  // ============ Tab Content (List + Refresh) ============
  Widget _tabContent({
    required List<RjscResponseDTO> list,
    required bool isApproved,
    required String emptyMessage,
    required IconData emptyIcon,
    required Color emptyColor,
  }) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: _primaryGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 60),
            _emptySectionView(
              message: emptyMessage,
              icon: emptyIcon,
              color: emptyColor,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildRjscCard(list[index], isApproved: isApproved);
        },
      ),
    );
  }

  // ============ Count Badge ============
  Widget _countBadge(int count, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  // ============ Error View ============
  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 60, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: _textGrey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
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

  // ============ Overall Empty View ============
  Widget _emptyOverallView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: _lightGreenBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open_outlined,
                size: 48, color: _primaryGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'No RJSC filings yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your RJSC submissions will appear here',
            style: GoogleFonts.inter(fontSize: 13, color: _textGrey),
          ),
        ],
      ),
    );
  }

  // ============ Empty Section View ============
  Widget _emptySectionView({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: color.withOpacity(0.7)),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull down to refresh',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: _textGrey),
          ),
        ],
      ),
    );
  }

  // ============ RJSC Card ============
  Widget _buildRjscCard(RjscResponseDTO rjsc, {required bool isApproved}) {
    final process = rjsc.registrationProcess;
    final statusColor = isApproved ? _primaryGreen : _pendingAmber;
    final statusBg = isApproved ? _lightGreenBg : _pendingBg;
    final statusText = isApproved ? 'Approved' : 'Pending';
    final statusIcon =
        isApproved ? Icons.check_circle : Icons.access_time_filled;

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
            // ---- Top Row ----
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.business,
                      color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rjsc.companyName.isEmpty
                            ? 'Untitled Company'
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
                      Text(
                        'Reg No: ${rjsc.registrationNo}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: _textGrey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 3),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
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

            // ---- Bottom Row ----
            Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    size: 16, color: _textGrey),
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
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: _textGrey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(rjsc.year),
                  style: GoogleFonts.inter(
                      fontSize: 12, color: _textGrey),
                ),
              ],
            ),

            // ---- Advocate (only for approved) ----
            if (isApproved &&
                (process?.advocateName.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.gavel, size: 12, color: _textGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Advocate: ${process!.advocateName}',
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

  // ============ Date Formatter ============
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}