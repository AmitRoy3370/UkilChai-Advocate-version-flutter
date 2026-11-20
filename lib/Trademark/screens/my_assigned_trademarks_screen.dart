// lib/Trademark/screens/my_assigned_trademarks_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trademark_response_dto.dart';
import '../services/trademark_service.dart';
import 'trademark_details_screen.dart';

class MyAssignedTrademarksScreen extends StatefulWidget {
  const MyAssignedTrademarksScreen({super.key});

  @override
  State<MyAssignedTrademarksScreen> createState() =>
      _MyAssignedTrademarksScreenState();
}

class _MyAssignedTrademarksScreenState
    extends State<MyAssignedTrademarksScreen> {
  static const Color _primaryPurple = Color(0xFF6A1B9A);

  List<TrademarkResponse> _assignedTrademarks = [];
  bool _isLoading = true;
  String? _error;
  String? _myAdvocateId;

  @override
  void initState() {
    super.initState();
    _loadAssignedTrademarks();
  }

  Future<void> _loadAssignedTrademarks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final advocateId = (prefs.getString('advocateId') ?? '').trim();

      if (!mounted) return;
      _myAdvocateId = advocateId;

      if (advocateId.isEmpty) {
        setState(() {
          _assignedTrademarks = [];
          _isLoading = false;
          _error = 'No advocate ID found in SharedPreferences.';
        });
        return;
      }

      final res = await TrademarkService.findAll();
      if (!mounted) return;

      if (res['status'] == 'success') {
        final all = TrademarkService.parseList(res);
        final mine = all
            .where((t) =>
                t.registrationProcess != null &&
                t.registrationProcess!.advocateId == advocateId)
            .toList();

        setState(() {
          _assignedTrademarks = mine;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = res['message'] ?? 'Failed to load trademarks';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  Future<void> _openTrademarkDetails(TrademarkResponse trademark) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrademarkDetailsScreen(
          trademark: trademark,
          isOwner: false,
        ),
      ),
    );

    if (mounted) {
      await _loadAssignedTrademarks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Assigned Trademarks',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _loadAssignedTrademarks,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryPurple),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (_myAdvocateId != null && _myAdvocateId!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Advocate ID: $_myAdvocateId',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadAssignedTrademarks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_assignedTrademarks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAssignedTrademarks,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(Icons.gavel_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No assigned trademarks found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignedTrademarks,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _assignedTrademarks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final trademark = _assignedTrademarks[index];
          final name = trademark.trademarkName.trim().isEmpty
              ? 'Untitled Trademark'
              : trademark.trademarkName.trim();

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _openTrademarkDetails(trademark),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: _primaryPurple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}