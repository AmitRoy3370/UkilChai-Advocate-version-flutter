// lib/Copyright/screens/my_copyright_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../models/copyright_response_dto.dart';
import '../services/copyright_service.dart';
import '../screens/widgets/copyright_card.dart';
import 'copyright_details_screen.dart';
import 'copyright_registration_screen.dart';

class MyCopyrightScreen extends StatefulWidget {
  const MyCopyrightScreen({super.key});

  @override
  State<MyCopyrightScreen> createState() => _MyCopyrightScreenState();
}

class _MyCopyrightScreenState extends State<MyCopyrightScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<CopyrightResponseDTO> _all = [];
  bool _isLoading = true;
  String? _error;
  String _currentUserId = '';

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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    _currentUserId = await AuthService.getUserId() ?? '';

    if (_currentUserId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
      return;
    }

    final result = await CopyrightService.findByUserId(_currentUserId);

    if (!mounted) return;

    if (result['status'] == 'success') {
      final list = CopyrightService.parseList(result);
      setState(() {
        _all = list;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result['message'] ?? 'Failed to load';
      });
    }
  }

  /// Pending = registrationProcess == null
  List<CopyrightResponseDTO> get _pending => _all
      .where((c) => c.registrationProcess == null)
      .toList();

  /// Approved = registrationProcess != null && status == true
  List<CopyrightResponseDTO> get _approved => _all
      .where((c) =>
          c.registrationProcess != null &&
          c.registrationProcess!.status == true)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'My Copyright',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1A3FBF),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF1A3FBF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(text: 'Approved (${_approved.length})'),
            Tab(text: 'Pending (${_pending.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(
                      items: _approved,
                      emptyMessage: 'No approved copyrights yet',
                      emptyIcon: Icons.verified_outlined,
                    ),
                    _buildList(
                      items: _pending,
                      emptyMessage:
                          'No pending applications. Start by registering a new copyright.',
                      emptyIcon: Icons.hourglass_empty,
                      showRegisterButton: true,
                    ),
                  ],
                ),
    );
  }

  Widget _buildList({
    required List<CopyrightResponseDTO> items,
    required String emptyMessage,
    required IconData emptyIcon,
    bool showRegisterButton = false,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              if (showRegisterButton) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CopyrightRegistrationScreen(),
                      ),
                    );
                    if (res == true) _loadData();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Register New Copyright'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3FBF),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
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
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => CopyrightDetailsScreen(
                    copyright: item,
                    isOwner: true,
                  ),
                ),
              );
              if (changed == true) _loadData();
            },
          );
        },
      ),
    );
  }

  Widget _errorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}