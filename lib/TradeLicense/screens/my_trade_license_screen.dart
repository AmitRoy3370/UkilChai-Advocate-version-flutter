// lib/TradeLicense/screens/my_trade_license_screen.dart

import 'package:flutter/material.dart';
import '../../Auth/AuthService.dart';
import '../models/trade_license_response_dto.dart';
import '../services/trade_license_service.dart';
import 'widgets/trade_license_card.dart';
import 'trade_license_details_screen.dart';
import 'trade_license_registration_screen.dart';

class MyTradeLicenseScreen extends StatefulWidget {
  const MyTradeLicenseScreen({super.key});

  @override
  State<MyTradeLicenseScreen> createState() => _MyTradeLicenseScreenState();
}

class _MyTradeLicenseScreenState extends State<MyTradeLicenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<TradeLicenseResponseDTO> _all = [];
  bool _isLoading = true;
  String? _error;

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

    final userId = await AuthService.getUserId() ?? '';
    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
      return;
    }

    final result = await TradeLicenseService.findByUserId(userId);
    if (!mounted) return;

    if (result['status'] == 'success') {
      setState(() {
        _all = TradeLicenseService.parseList(result);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = result['message'] ?? 'Failed to load';
      });
    }
  }

  List<TradeLicenseResponseDTO> get _pending => _all
      .where((c) => c.tradeLicenseRegistrationProcess == null)
      .toList();

  List<TradeLicenseResponseDTO> get _approved => _all
      .where((c) =>
          c.tradeLicenseRegistrationProcess != null &&
          c.tradeLicenseRegistrationProcess!.status == true)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('My Trade License',
            style: TextStyle(color: Colors.black87, fontSize: 18)),
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
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
                      emptyMessage: 'No approved trade licenses yet',
                      emptyIcon: Icons.verified_outlined,
                    ),
                    _buildList(
                      items: _pending,
                      emptyMessage:
                          'No pending applications. Start by registering a new trade license.',
                      emptyIcon: Icons.hourglass_empty,
                      showRegisterButton: true,
                    ),
                  ],
                ),
    );
  }

  Widget _buildList({
    required List<TradeLicenseResponseDTO> items,
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
              Text(emptyMessage,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              if (showRegisterButton) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const TradeLicenseRegistrationScreen(),
                      ),
                    );
                    if (res == true) _loadData();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Register New Trade License'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E7A3A),
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
          return TradeLicenseCard(
            license: item,
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => TradeLicenseDetailsScreen(
                    license: item,
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
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}